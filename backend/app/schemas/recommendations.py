from __future__ import annotations

from datetime import date, datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


RecommendationCategory = Literal["balance", "calm", "energy", "focus", "reflection"]
RecommendationKind = Literal["timed_action", "habit", "instant_action", "reflection"]
RecommendationStatus = Literal["pending", "selected", "completed"]


class RecommendationItemResponse(BaseModel):
    id: int
    batch_id: int
    position: int
    category: str
    kind: str
    title: str
    rationale: str
    action_payload: dict[str, Any] = Field(default_factory=dict)
    estimated_duration_minutes: int | None = None
    follow_up_text: str | None = None
    status: str
    completed_at: datetime | None = None
    created_at: datetime


class RecommendationBatchResponse(BaseModel):
    id: int
    user_id: int
    category: str
    batch_date: date
    is_active: bool
    created_at: datetime
    items: list[RecommendationItemResponse]


class RecommendationHistoryResponse(BaseModel):
    batches: list[RecommendationBatchResponse]


class RecommendationGenerationRequest(BaseModel):
    user_id: int
    category: RecommendationCategory = "balance"


class RecommendationInteractionRequest(BaseModel):
    user_id: int
    event_type: str
    payload: dict[str, Any] = Field(default_factory=dict)


class AdoptHabitRequest(BaseModel):
    user_id: int


class CreateHabitRequest(BaseModel):
    user_id: int
    name: str = Field(..., min_length=1, max_length=255)


class UserHabitResponse(BaseModel):
    id: int
    user_id: int
    source_recommendation_item_id: int | None = None
    name: str
    category: str
    cue_text: str | None = None
    reason_text: str | None = None
    is_active: bool
    created_at: datetime
    archived_at: datetime | None = None


class DailyHabitChecklistItemResponse(BaseModel):
    habit: UserHabitResponse
    is_completed: bool
    completed_at: datetime | None = None


class DailyHabitChecklistResponse(BaseModel):
    date: date
    habits: list[DailyHabitChecklistItemResponse]


class HabitCheckRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    user_id: int
    check_date: date | None = Field(default=None, alias="date")
    completed: bool = True