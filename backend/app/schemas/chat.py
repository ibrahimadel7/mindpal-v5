from datetime import datetime

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    user_id: int
    conversation_id: int
    message: str = Field(min_length=1, max_length=5000)


class ChatResponse(BaseModel):
    conversation_id: int
    user_message_id: int
    assistant_message_id: int
    response: str
    timestamp: datetime
