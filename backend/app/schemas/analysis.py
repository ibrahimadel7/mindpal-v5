from pydantic import BaseModel, Field


class EmotionItem(BaseModel):
    label: str
    confidence: float = Field(ge=0.0, le=1.0)


class EmotionDetectionResult(BaseModel):
    emotions: list[EmotionItem]


class HabitItem(BaseModel):
    habit: str
    confidence: float = Field(ge=0.0, le=1.0)


class HabitDetectionResult(BaseModel):
    habits: list[HabitItem]
