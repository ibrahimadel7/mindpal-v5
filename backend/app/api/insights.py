from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.time_patterns import TimePatternAnalytics
from app.database.session import get_db_session
from app.schemas.insights import (
    AIOverviewInsight,
    DailyEmotionTrend,
    DailyHabitTrend,
    EmotionInsight,
    HabitEmotionLinkInsight,
    HabitInsight,
    OverviewInsight,
    SummaryInsight,
    TimePatternInsight,
)
from app.services.llm_service import LLMService

router = APIRouter(prefix="/insights", tags=["insights"])
analytics = TimePatternAnalytics()


@router.get("/emotions", response_model=list[EmotionInsight])
async def insights_emotions(user_id: int, db: AsyncSession = Depends(get_db_session)) -> list[EmotionInsight]:
    rows = await analytics.emotion_stats(db, user_id=user_id)
    return [EmotionInsight.model_validate(item) for item in rows]


@router.get("/habits", response_model=list[HabitInsight])
async def insights_habits(
    user_id: int,
    period: Literal["week", "month", "all"] | None = Query(default=None, description="Time period filter"),
    db: AsyncSession = Depends(get_db_session),
) -> list[HabitInsight]:
    rows = await analytics.habit_stats(db, user_id=user_id, period=period)
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


@router.get("/ai-overview", response_model=AIOverviewInsight)
async def insights_ai_overview(user_id: int, db: AsyncSession = Depends(get_db_session)) -> AIOverviewInsight:
    """Generate an AI-powered personalized overview of the user's emotional and behavioral patterns."""
    # Gather data
    emotions = await analytics.emotion_stats(db, user_id=user_id)
    habits = await analytics.habit_stats(db, user_id=user_id)
    overview = await analytics.overview_metrics(db, user_id=user_id)
    recent_trends = await analytics.daily_emotion_trends(db, user_id=user_id)

    # Build context for LLM
    emotion_text = ", ".join([f"{e['label']} ({e['count']}x)" for e in emotions[:5]]) or "no emotions recorded"
    habit_text = ", ".join([f"{h['habit']} ({h['count']}x)" for h in habits[:5]]) or "no habits recorded"
    dominant_emotion = overview.get("dominant_emotion") or "balanced"
    dominant_habit = overview.get("dominant_habit") or "reflection"
    total_messages = overview.get("total_messages", 0)
    active_days = overview.get("active_days", 0)

    # Recent trend (last 3 days)
    recent_emotions = []
    for trend in recent_trends[-3:]:
        if trend.get("emotions"):
            top = max(trend["emotions"], key=lambda x: x.get("count", 0), default=None)
            if top:
                recent_emotions.append(top.get("label", "neutral"))

    recent_trend_text = ", ".join(recent_emotions) if recent_emotions else "steady"

    llm = LLMService()
    if not llm.is_configured:
        # Fallback response when LLM is not configured
        return AIOverviewInsight(
            greeting="Welcome back!",
            current_feeling=f"Based on recent patterns, you seem to be feeling {dominant_emotion.lower()}.",
            emotion_summary=f"Your top emotions lately: {emotion_text}.",
            habit_summary=f"Your frequent activities: {habit_text}.",
            encouragement="Keep tracking your journey - every reflection helps you grow.",
        )

    prompt = f"""You are MindPal, a warm and empathetic mental wellness companion. Generate a brief, personalized overview for a user based on their recent data.

User Data:
- Total reflections: {total_messages}
- Active days: {active_days}
- Top emotions: {emotion_text}
- Dominant emotion: {dominant_emotion}
- Top habits/activities: {habit_text}
- Recent emotional trend (last 3 days): {recent_trend_text}

Generate a JSON response with exactly these fields (keep each under 60 words):
{{
  "greeting": "A warm, personalized greeting based on time of day or their patterns",
  "current_feeling": "An empathetic observation about how they might be feeling right now based on recent trends",
  "emotion_summary": "A brief, supportive summary of their emotional patterns without being clinical",
  "habit_summary": "An encouraging note about their habits and activities",
  "encouragement": "A motivating, genuine message to support their wellness journey"
}}

Be warm, genuine, and supportive. Avoid clinical language. Respond ONLY with the JSON object."""

    try:
        response = await llm.generate_chat(prompt, temperature=0.7, max_tokens=400)
        # Parse JSON from response
        import json
        # Clean up response if it has markdown code blocks
        clean_response = response.strip()
        if clean_response.startswith("```"):
            clean_response = clean_response.split("```")[1]
            if clean_response.startswith("json"):
                clean_response = clean_response[4:]
        clean_response = clean_response.strip()
        
        data = json.loads(clean_response)
        return AIOverviewInsight(
            greeting=data.get("greeting", "Welcome back!"),
            current_feeling=data.get("current_feeling", f"You seem to be feeling {dominant_emotion.lower()}."),
            emotion_summary=data.get("emotion_summary", f"Your top emotions: {emotion_text}."),
            habit_summary=data.get("habit_summary", f"Your activities: {habit_text}."),
            encouragement=data.get("encouragement", "Keep reflecting on your journey."),
        )
    except Exception:
        # Fallback on any error
        return AIOverviewInsight(
            greeting="Welcome back!",
            current_feeling=f"Based on recent patterns, you seem to be feeling {dominant_emotion.lower()}.",
            emotion_summary=f"Your top emotions lately: {emotion_text}.",
            habit_summary=f"Your frequent activities: {habit_text}.",
            encouragement="Keep tracking your journey - every reflection helps you grow.",
        )
