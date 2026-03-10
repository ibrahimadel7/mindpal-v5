from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.time_patterns import TimePatternAnalytics
from app.database.session import get_db_session
from app.schemas.insights import EmotionInsight, HabitInsight, SummaryInsight, TimePatternInsight

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
