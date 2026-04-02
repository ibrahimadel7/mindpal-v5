import logging
from datetime import datetime, UTC

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.models.conversation import Conversation
from app.models.message import Message
from app.models.user import User
from app.services.chat_memory_service import ChatMemoryService
from app.schemas.conversation import (
    ConversationListResponse,
    ConversationMessagesResponse,
    ConversationResponse,
    CreateConversationRequest,
    MessageResponse,
)

router = APIRouter(tags=["conversations"])
logger = logging.getLogger(__name__)
memory_service = ChatMemoryService()


@router.get("/conversations", response_model=ConversationListResponse)
async def list_conversations(user_id: int | None = None, db: AsyncSession = Depends(get_db_session)) -> ConversationListResponse:
    query = select(Conversation)
    if user_id is not None:
        query = query.where(Conversation.user_id == user_id)
    rows = (await db.execute(query.order_by(Conversation.created_at.desc(), Conversation.id.desc()))).scalars().all()
    return ConversationListResponse(conversations=[ConversationResponse.model_validate(row, from_attributes=True) for row in rows])


@router.post("/conversations", response_model=ConversationResponse)
async def create_conversation(
    payload: CreateConversationRequest,
    db: AsyncSession = Depends(get_db_session),
) -> ConversationResponse:
    user = (await db.execute(select(User).where(User.id == payload.user_id))).scalar_one_or_none()
    if user is None:
        user = User(id=payload.user_id)
        db.add(user)
        await db.flush()

    convo = Conversation(user_id=payload.user_id, title=payload.title)
    db.add(convo)
    await db.commit()
    await db.refresh(convo)
    return ConversationResponse.model_validate(convo, from_attributes=True)


@router.post("/conversations/{id}/close", response_model=ConversationResponse)
async def close_conversation(
    id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> ConversationResponse:
    conversation = (
        await db.execute(select(Conversation).where(Conversation.id == id, Conversation.user_id == user_id))
    ).scalar_one_or_none()
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found for this user")

    if not conversation.is_closed:
        conversation.is_closed = True
        conversation.closed_at = datetime.now(UTC)
        try:
            await memory_service.summarize_and_store_conversation(
                db,
                user_id=user_id,
                conversation_id=id,
                refresh_existing=True,
            )
        except Exception:  # noqa: BLE001
            logger.exception("Failed to generate chat memory for conversation_id=%s user_id=%s", id, user_id)

        await db.commit()
        await db.refresh(conversation)

    return ConversationResponse.model_validate(conversation, from_attributes=True)


@router.post("/conversations/{id}/reopen", response_model=ConversationResponse)
async def reopen_conversation(
    id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> ConversationResponse:
    conversation = (
        await db.execute(select(Conversation).where(Conversation.id == id, Conversation.user_id == user_id))
    ).scalar_one_or_none()
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found for this user")

    if conversation.is_closed:
        conversation.is_closed = False
        conversation.closed_at = None
        await db.commit()
        await db.refresh(conversation)

    return ConversationResponse.model_validate(conversation, from_attributes=True)


@router.get("/conversations/{id}/messages", response_model=ConversationMessagesResponse)
async def list_conversation_messages(
    id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> ConversationMessagesResponse:
    conversation = (
        await db.execute(select(Conversation).where(Conversation.id == id, Conversation.user_id == user_id))
    ).scalar_one_or_none()
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found for this user")

    messages = (
        await db.execute(select(Message).where(Message.conversation_id == id).order_by(Message.timestamp.asc(), Message.id.asc()))
    ).scalars().all()

    return ConversationMessagesResponse(
        messages=[
            MessageResponse(
                id=message.id,
                conversation_id=message.conversation_id,
                role=message.role.value,
                content=message.content,
                timestamp=message.timestamp,
            )
            for message in messages
        ]
    )


@router.delete("/conversations/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_conversation(id: int, db: AsyncSession = Depends(get_db_session)) -> None:
    logger.info("Delete requested for conversation_id=%s", id)
    conversation = (await db.execute(select(Conversation).where(Conversation.id == id))).scalar_one_or_none()
    if conversation is None:
        logger.warning("Delete requested for non-existent conversation_id=%s", id)
        raise HTTPException(status_code=404, detail="Conversation not found")

    # Count messages before deletion for logging purposes
    related_message_ids = (
        await db.execute(select(Message.id).where(Message.conversation_id == id))
    ).scalars().all()
    message_count = len(related_message_ids)

    try:
        # Use ORM cascade to delete conversation and all related messages/analysis
        await db.delete(conversation)
        await db.commit()
        logger.info(
            "Deleted conversation_id=%s and %s related messages",
            id,
            message_count,
        )
    except Exception:
        await db.rollback()
        logger.exception("Failed to delete conversation_id=%s", id)
        raise HTTPException(status_code=500, detail="Failed to delete conversation")
