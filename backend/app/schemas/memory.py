from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel

MemoryCategoryLiteral = Literal["habit", "emotion", "goal", "preference"]


class MemoryProfileResponse(BaseModel):
    user_id: int
    is_paused: bool
    context: dict
    habits: list[str]
    emotions: list[str]
    goals: list[str]
    updated_at: datetime
    last_summarized_at: datetime | None


class MemoryEntryResponse(BaseModel):
    id: int
    user_id: int
    category: MemoryCategoryLiteral
    content: str
    relevance_score: float
    emotional_significance: float
    recurrence_count: int
    source_conversation_id: int | None
    is_active: bool
    created_at: datetime
    updated_at: datetime


class MemoryListResponse(BaseModel):
    profile: MemoryProfileResponse
    entries: list[MemoryEntryResponse]


class MemoryPauseResponse(BaseModel):
    user_id: int
    is_paused: bool


class MemoryTrendPoint(BaseModel):
    date: str
    total: int
    by_category: dict[str, int]


class MemoryTrendsResponse(BaseModel):
    user_id: int
    window_days: int
    trends: list[MemoryTrendPoint]
