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


class PatternAnalysis(BaseModel):
    """Result of internal pattern analysis before surfacing to user."""
    primary_pattern: str | None = Field(None, description="Main detected pattern or null if none found")
    confidence: float = Field(0.0, ge=0.0, le=1.0, description="Confidence in the pattern detection (0.0-1.0)")
    supporting_signals: list[str] = Field(default_factory=list, description="Key phrases supporting the pattern")
    should_surface: bool = Field(False, description="Whether pattern should be surfaced to user in response")
