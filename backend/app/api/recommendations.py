from __future__ import annotations

from datetime import date
import logging

from fastapi import APIRouter, Depends, HTTPException, status
import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db_session
from app.schemas.recommendations import (
    AdoptHabitRequest,
    CreateHabitRequest,
    DailyHabitChecklistItemResponse,
    DailyHabitChecklistResponse,
    HabitCheckRequest,
    RecommendationBatchResponse,
    RecommendationGenerationRequest,
    RecommendationHistoryResponse,
    RecommendationInteractionRequest,
    RecommendationItemResponse,
    UserHabitResponse,
)
from app.services.recommendation_service import RecommendationService

router = APIRouter(prefix="/recommendations", tags=["recommendations"])
recommendation_service = RecommendationService()
logger = logging.getLogger(__name__)


def _item_response(item) -> RecommendationItemResponse:
    return RecommendationItemResponse(
        id=item.id,
        batch_id=item.batch_id,
        position=item.position,
        category=item.category,
        kind=item.kind,
        title=item.title,
        rationale=item.rationale,
        action_payload=item.action_payload_json,
        estimated_duration_minutes=item.estimated_duration_minutes,
        follow_up_text=item.follow_up_text,
        status=item.status,
        completed_at=item.completed_at,
        created_at=item.created_at,
    )


def _batch_response(batch) -> RecommendationBatchResponse:
    items = sorted(batch.items, key=lambda item: (item.position, item.id))
    return RecommendationBatchResponse(
        id=batch.id,
        user_id=batch.user_id,
        category=batch.category,
        batch_date=batch.batch_date,
        is_active=batch.is_active,
        created_at=batch.created_at,
        items=[_item_response(item) for item in items],
    )


@router.get("/today", response_model=RecommendationBatchResponse)
async def get_today_recommendations(
    user_id: int,
    category: str = "balance",
    db: AsyncSession = Depends(get_db_session),
) -> RecommendationBatchResponse:
    try:
        batch = await recommendation_service.get_or_create_today_batch(db, user_id=user_id, category=category)
    except httpx.HTTPStatusError as exc:
        logger.exception("Recommendations upstream request failed")
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
        logger.exception("Recommendations generation failed")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Recommendations are temporarily unavailable.",
        ) from exc
    return _batch_response(batch)


@router.post("/generate", response_model=RecommendationBatchResponse)
async def generate_recommendations(
    payload: RecommendationGenerationRequest,
    db: AsyncSession = Depends(get_db_session),
) -> RecommendationBatchResponse:
    try:
        batch = await recommendation_service.generate_batch(db, user_id=payload.user_id, category=payload.category)
    except httpx.HTTPStatusError as exc:
        logger.exception("Recommendations upstream request failed")
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
        logger.exception("Recommendations generation failed")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Recommendations are temporarily unavailable.",
        ) from exc
    return _batch_response(batch)


@router.get("/history", response_model=RecommendationHistoryResponse)
async def recommendations_history(
    user_id: int,
    limit: int = 10,
    db: AsyncSession = Depends(get_db_session),
) -> RecommendationHistoryResponse:
    batches = await recommendation_service.get_history(db, user_id=user_id, limit=limit)
    return RecommendationHistoryResponse(batches=[_batch_response(batch) for batch in batches])


@router.post("/items/{item_id}/select", response_model=RecommendationItemResponse)
async def select_recommendation_item(
    item_id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> RecommendationItemResponse:
    try:
        item = await recommendation_service.select_item(db, user_id=user_id, item_id=item_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return _item_response(item)


@router.post("/items/{item_id}/complete", response_model=RecommendationItemResponse)
async def complete_recommendation_item(
    item_id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> RecommendationItemResponse:
    try:
        item = await recommendation_service.complete_item(db, user_id=user_id, item_id=item_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return _item_response(item)


@router.post("/items/{item_id}/interactions", status_code=status.HTTP_204_NO_CONTENT)
async def recommendation_item_interaction(
    item_id: int,
    payload: RecommendationInteractionRequest,
    db: AsyncSession = Depends(get_db_session),
) -> None:
    try:
        await recommendation_service.log_item_interaction(
            db,
            user_id=payload.user_id,
            item_id=item_id,
            event_type=payload.event_type,
            payload=payload.payload,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/items/{item_id}/habit", response_model=UserHabitResponse)
async def recommendation_item_to_habit(
    item_id: int,
    payload: AdoptHabitRequest,
    db: AsyncSession = Depends(get_db_session),
) -> UserHabitResponse:
    try:
        habit = await recommendation_service.adopt_habit(db, user_id=payload.user_id, item_id=item_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return UserHabitResponse.model_validate(habit, from_attributes=True)


@router.post("/habits", response_model=UserHabitResponse, status_code=status.HTTP_201_CREATED)
async def create_habit(
    payload: CreateHabitRequest,
    db: AsyncSession = Depends(get_db_session),
) -> UserHabitResponse:
    habit = await recommendation_service.create_habit(db, user_id=payload.user_id, name=payload.name)
    return UserHabitResponse.model_validate(habit, from_attributes=True)


@router.get("/habits/checklist", response_model=DailyHabitChecklistResponse)
async def recommendations_habit_checklist(
    user_id: int,
    for_date: date | None = None,
    db: AsyncSession = Depends(get_db_session),
) -> DailyHabitChecklistResponse:
    rows = await recommendation_service.get_daily_checklist(db, user_id=user_id, for_date=for_date)
    target_date = for_date or recommendation_service._today()
    return DailyHabitChecklistResponse(
        date=target_date,
        habits=[
            DailyHabitChecklistItemResponse(
                habit=UserHabitResponse.model_validate(habit, from_attributes=True),
                is_completed=bool(check.is_completed) if check is not None else False,
                completed_at=check.completed_at if check is not None else None,
            )
            for habit, check in rows
        ],
    )


@router.put("/habits/{habit_id}/check", response_model=DailyHabitChecklistItemResponse)
async def recommendations_set_habit_check(
    habit_id: int,
    payload: HabitCheckRequest,
    db: AsyncSession = Depends(get_db_session),
) -> DailyHabitChecklistItemResponse:
    try:
        check = await recommendation_service.set_habit_check(
            db,
            user_id=payload.user_id,
            habit_id=habit_id,
            for_date=payload.check_date,
            completed=payload.completed,
        )
        rows = await recommendation_service.get_daily_checklist(db, user_id=payload.user_id, for_date=check.check_date)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    for habit, habit_check in rows:
        if habit.id == habit_id:
            return DailyHabitChecklistItemResponse(
                habit=UserHabitResponse.model_validate(habit, from_attributes=True),
                is_completed=bool(habit_check.is_completed) if habit_check is not None else False,
                completed_at=habit_check.completed_at if habit_check is not None else None,
            )

    raise HTTPException(status_code=404, detail="Habit not found for this user")


@router.delete("/habits/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
async def recommendations_delete_habit(
    habit_id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db_session),
) -> None:
    try:
        await recommendation_service.delete_habit(db, user_id=user_id, habit_id=habit_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc