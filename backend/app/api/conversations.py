from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.models.conversation import Conversation
from app.models.message import Message
from app.models.user import User
from app.schemas.conversation import (
    ConversationListResponse,
    ConversationMessagesResponse,
    ConversationResponse,
    CreateConversationRequest,
    MessageResponse,
)

router = APIRouter(tags=["conversations"])


@router.get("/conversations", response_model=ConversationListResponse)
async def list_conversations(user_id: int | None = None, db: AsyncSession = Depends(get_db_session)) -> ConversationListResponse:
    query = select(Conversation)
    if user_id is not None:
        query = query.where(Conversation.user_id == user_id)
    rows = (await db.execute(query)).scalars().all()
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
    conversation = (await db.execute(select(Conversation).where(Conversation.id == id))).scalar_one_or_none()
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation not found")

    await db.execute(delete(Conversation).where(Conversation.id == id))
    await db.commit()
