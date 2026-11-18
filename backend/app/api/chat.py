import json
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.models.conversation import Conversation
from app.rag.pipeline import RAGPipeline
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.llm_service import LLMServiceError

router = APIRouter(tags=["chat"])
logger = logging.getLogger(__name__)


def _sse_event(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data, default=str)}\n\n"


@router.post("/chat", response_model=ChatResponse)
async def chat(payload: ChatRequest, db: AsyncSession = Depends(get_db_session)) -> ChatResponse:
    conversation = (
        await db.execute(
            select(Conversation).where(Conversation.id == payload.conversation_id, Conversation.user_id == payload.user_id)
        )
    ).scalar_one_or_none()

    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found for this user")
    if conversation.is_closed:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Conversation is closed")

    pipeline = RAGPipeline()
    try:
        result = await pipeline.run(
            db=db,
            conversation_id=payload.conversation_id,
            user_id=payload.user_id,
            user_text=payload.message,
        )
    except LLMServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
    except httpx.HTTPStatusError as exc:
        logger.exception("Chat upstream request failed")
        if exc.response.status_code == status.HTTP_401_UNAUTHORIZED:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="AI provider authentication failed. Check GROQ_API_KEY.",
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI provider is temporarily unavailable.",
        ) from exc
    except Exception as exc:  # noqa: BLE001
        logger.exception("Chat pipeline failed")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Chat service is temporarily unavailable.",
        ) from exc
    return ChatResponse.model_validate(result)


@router.post("/chat/stream")
async def chat_stream(payload: ChatRequest, db: AsyncSession = Depends(get_db_session)) -> StreamingResponse:
    conversation = (
        await db.execute(
            select(Conversation).where(Conversation.id == payload.conversation_id, Conversation.user_id == payload.user_id)
        )
    ).scalar_one_or_none()

    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found for this user")
    if conversation.is_closed:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Conversation is closed")

    pipeline = RAGPipeline()

    async def event_generator():
        try:
            async for event in pipeline.run_stream(
                db=db,
                conversation_id=payload.conversation_id,
                user_id=payload.user_id,
                user_text=payload.message,
            ):
                event_type = event.pop("type", "token")
                yield _sse_event(event_type, event)
        except Exception as exc:  # noqa: BLE001
            # Stream-level error events let the frontend keep partial text and show recoverable state.
            yield _sse_event(
                "error",
                {
                    "message": "Streaming failed before completion.",
                    "error_code": "stream_internal_error",
                    "retryable": True,
                    "partial_saved": False,
                },
            )

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
