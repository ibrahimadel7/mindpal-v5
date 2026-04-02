from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.models.user_memory import UserMemoryEntry
from app.schemas.memory import (
    MemoryEntryResponse,
    MemoryListResponse,
    MemoryPauseResponse,
    MemoryProfileResponse,
    MemoryTrendsResponse,
)
from app.services.memory_service import MemoryService

router = APIRouter(prefix="/memory", tags=["memory"])
memory_service = MemoryService()


def _to_profile_response(profile: object) -> MemoryProfileResponse:
    return MemoryProfileResponse(
        user_id=profile.user_id,
        is_paused=profile.is_paused,
        context=profile.context_json,
        habits=profile.habits_json,
        emotions=profile.emotions_json,
        goals=profile.goals_json,
        updated_at=profile.updated_at,
        last_summarized_at=profile.last_summarized_at,
    )


def _to_entry_response(entry: UserMemoryEntry) -> MemoryEntryResponse:
    return MemoryEntryResponse(
        id=entry.id,
        user_id=entry.user_id,
        category=entry.category,
        content=entry.content,
        relevance_score=entry.relevance_score,
        emotional_significance=entry.emotional_significance,
        recurrence_count=entry.recurrence_count,
        source_conversation_id=entry.source_conversation_id,
        is_active=entry.is_active,
        created_at=entry.created_at,
        updated_at=entry.updated_at,
    )


@router.get("", response_model=MemoryListResponse)
async def list_memory(
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> MemoryListResponse:
    profile = await memory_service.ensure_user_memory(db, user_id=user_id)
    entries = await memory_service.list_memory_entries(
        db,
        user_id=user_id,
        category=None,
        include_inactive=False,
    )
    return MemoryListResponse(
        profile=_to_profile_response(profile),
        entries=[_to_entry_response(entry) for entry in entries],
    )


@router.post("/pause", response_model=MemoryPauseResponse)
async def pause_memory(user_id: int, db: AsyncSession = Depends(get_db_session)) -> MemoryPauseResponse:
    profile = await memory_service.set_memory_pause(db, user_id=user_id, paused=True)
    await db.commit()
    return MemoryPauseResponse(user_id=profile.user_id, is_paused=profile.is_paused)


@router.post("/resume", response_model=MemoryPauseResponse)
async def resume_memory(user_id: int, db: AsyncSession = Depends(get_db_session)) -> MemoryPauseResponse:
    profile = await memory_service.set_memory_pause(db, user_id=user_id, paused=False)
    await db.commit()
    return MemoryPauseResponse(user_id=profile.user_id, is_paused=profile.is_paused)


@router.get("/trends", response_model=MemoryTrendsResponse)
async def memory_trends(
    user_id: int,
    days: int = 30,
    db: AsyncSession = Depends(get_db_session),
) -> MemoryTrendsResponse:
    points = await memory_service.memory_trends(db, user_id=user_id, days=days)
    return MemoryTrendsResponse(user_id=user_id, window_days=days, trends=points)
