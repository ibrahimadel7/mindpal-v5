from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.time_patterns import TimePatternAnalytics
from app.database.session import get_db_session
from app.schemas.insights import (
    DailyEmotionTrend,
    DailyHabitTrend,
    EmotionInsight,
    HabitEmotionLinkInsight,
    HabitInsight,
    OverviewInsight,
    SummaryInsight,
    TimePatternInsight,
)

router = APIRouter(prefix="/insights", tags=["insights"])
analytics = TimePatternAnalytics()


@router.get("/emotions", response_model=list[EmotionInsight])
async def insights_emotions(user_id: int, db: AsyncSession = Depends(get_db_session)) -> list[EmotionInsight]:
    rows = await analytics.emotion_stats(db, user_id=user_id)
    return [EmotionInsight.model_validate(item) for item in rows]


@router.get("/habits", response_model=list[HabitInsight])
async def insights_habits(user_id: int, db: AsyncSession = Depends(get_db_session)) -> list[HabitInsight]:
    rows = await analytics.habit_stats(db, user_id=user_id)
    return [HabitInsight.model_validate(item) for item in rows]


@router.get("/time", response_model=list[TimePatternInsight])
async def insights_time(user_id: int, db: AsyncSession = Depends(get_db_session)) -> list[TimePatternInsight]:
    rows = await analytics.time_patterns(db, user_id=user_id)
    return [TimePatternInsight.model_validate(item) for item in rows]


@router.get("/summary", response_model=SummaryInsight)
async def insights_summary(user_id: int, db: AsyncSession = Depends(get_db_session)) -> SummaryInsight:
    emotions = await analytics.emotion_stats(db, user_id=user_id)
    habits = await analytics.habit_stats(db, user_id=user_id)
    time_rows = await analytics.time_patterns(db, user_id=user_id)
    return SummaryInsight(
        emotion_stats=[EmotionInsight.model_validate(item) for item in emotions],
        habit_stats=[HabitInsight.model_validate(item) for item in habits],
        time_patterns=[TimePatternInsight.model_validate(item) for item in time_rows],
    )


@router.get("/overview", response_model=OverviewInsight)
async def insights_overview(user_id: int, db: AsyncSession = Depends(get_db_session)) -> OverviewInsight:
    row = await analytics.overview_metrics(db, user_id=user_id)
    return OverviewInsight.model_validate(row)


@router.get("/trends/emotions", response_model=list[DailyEmotionTrend])
async def insights_trends_emotions(user_id: int, db: AsyncSession = Depends(get_db_session)) -> list[DailyEmotionTrend]:
    rows = await analytics.daily_emotion_trends(db, user_id=user_id)
    return [DailyEmotionTrend.model_validate(item) for item in rows]


@router.get("/trends/habits", response_model=list[DailyHabitTrend])
async def insights_trends_habits(user_id: int, db: AsyncSession = Depends(get_db_session)) -> list[DailyHabitTrend]:
    rows = await analytics.daily_habit_trends(db, user_id=user_id)
    return [DailyHabitTrend.model_validate(item) for item in rows]


@router.get("/associations/habit-emotion", response_model=list[HabitEmotionLinkInsight])
async def insights_associations_habit_emotion(
    user_id: int,
    min_count: int = 1,
    top_n: int = 50,
    db: AsyncSession = Depends(get_db_session),
) -> list[HabitEmotionLinkInsight]:
    rows = await analytics.habit_emotion_links(db, user_id=user_id, min_count=min_count, top_n=top_n)
    return [HabitEmotionLinkInsight.model_validate(item) for item in rows]
