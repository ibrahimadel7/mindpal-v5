from datetime import datetime

from pydantic import BaseModel


class CreateConversationRequest(BaseModel):
    user_id: int
    title: str = "New Conversation"


class ConversationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    created_at: datetime


class ConversationListResponse(BaseModel):
    conversations: list[ConversationResponse]


class MessageResponse(BaseModel):
    id: int
    conversation_id: int
    role: str
    content: str
    timestamp: datetime


class ConversationMessagesResponse(BaseModel):
    messages: list[MessageResponse]
