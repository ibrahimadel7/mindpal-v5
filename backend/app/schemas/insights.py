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
