from pydantic import BaseModel


class EmotionInsight(BaseModel):
    label: str
    count: int


class HabitInsight(BaseModel):
    habit: str
    count: int


class TimePatternInsight(BaseModel):
    hour_of_day: int
    top_emotion: str
    message_count: int


class SummaryInsight(BaseModel):
    emotion_stats: list[EmotionInsight]
    habit_stats: list[HabitInsight]
    time_patterns: list[TimePatternInsight]


class OverviewInsight(BaseModel):
    total_messages: int
    active_days: int
    dominant_emotion: str | None
    dominant_habit: str | None


class DailyEmotionPoint(BaseModel):
    label: str
    count: int


class DailyEmotionTrend(BaseModel):
    date: str
    total: int
    emotions: list[DailyEmotionPoint]


class DailyHabitPoint(BaseModel):
    habit: str
    count: int


class DailyHabitTrend(BaseModel):
    date: str
    total: int
    habits: list[DailyHabitPoint]


class HabitEmotionLinkInsight(BaseModel):
    habit: str
    emotion: str
    co_occurrence: int
    habit_total: int
    link_strength: float
