import json

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.models.conversation import Conversation
from app.rag.pipeline import RAGPipeline
from app.schemas.chat import ChatRequest, ChatResponse

router = APIRouter(tags=["chat"])


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

    pipeline = RAGPipeline()
    result = await pipeline.run(
        db=db,
        conversation_id=payload.conversation_id,
        user_id=payload.user_id,
        user_text=payload.message,
    )
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
            yield _sse_event("error", {"message": f"Streaming failed: {exc}"})

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
