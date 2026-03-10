from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.models.conversation import Conversation
from app.rag.pipeline import RAGPipeline
from app.schemas.chat import ChatRequest, ChatResponse

router = APIRouter(tags=["chat"])


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
