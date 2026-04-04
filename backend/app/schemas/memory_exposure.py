from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class MemoryExposureLevel(str, Enum):
    HIDDEN = "hidden"
    SOFT_RECALL = "soft_recall"
    EXPLICIT_RECALL = "explicit_recall"


class MemoryConfidenceScore(BaseModel):
    memory_content: str = Field(min_length=1, max_length=1000)
    recency_score: float = Field(ge=0.0, le=1.0)
    frequency_score: float = Field(ge=0.0, le=1.0)
    specificity_score: float = Field(ge=0.0, le=1.0)
    is_highly_specific: bool = False
    days_since_mention: int = Field(ge=0)
    mention_count: int = Field(ge=0)

    @property
    def combined_confidence(self) -> float:
        weighted = (self.recency_score * 0.35) + (self.frequency_score * 0.35) + (self.specificity_score * 0.30)
        return max(0.0, min(weighted, 1.0))


class MemoryExposureContext(BaseModel):
    turn_number: int = Field(ge=1)
    escalation_turns: int = Field(ge=0, default=0)
    user_expressed_uncertainty: bool = False
    user_confirmed_direction: bool = False
    memory_was_user_mentioned: bool = False


class MemoryExposureDecision(BaseModel):
    exposure_level: MemoryExposureLevel = MemoryExposureLevel.HIDDEN
    should_include_memory: bool = False
    memory_reference_style: str = "none"
    justification: str = ""
    confidence_score: float = Field(ge=0.0, le=1.0, default=0.0)


class ResponseFilterResult(BaseModel):
    original_response: str
    filtered_response: str
    filters_applied: list[str] = Field(default_factory=list)
    specificity_score: float = Field(ge=0.0, le=1.0, default=0.0)
    emotional_density: int = Field(ge=0, default=0)
    improvements_made: dict[str, str] = Field(default_factory=dict)


USER_SIGNAL_UNCERTAINTY_KEYWORDS = {
    "not sure",
    "i don't know",
    "idk",
    "maybe",
    "unsure",
    "confused",
    "i guess",
    "perhaps",
}

USER_SIGNAL_CONFIRMATION_KEYWORDS = {
    "yes",
    "exactly",
    "that's right",
    "correct",
    "true",
    "makes sense",
    "spot on",
    "agreed",
}

BLOCKED_DATA_EXPOSURE_PHRASES = {
    "based on your data",
    "from your stored memories",
    "my system shows",
    "as recorded",
    "from previous logs",
    "according to your profile",
    "historical data indicates",
}

OVERCONFIDENT_REPLACEMENTS = {
    r"\byou are\b": "it seems you may be",
    r"\byou always\b": "it seems you often",
    r"\byou never\b": "it seems this has not come up lately",
    r"\bthis means\b": "this might mean",
    r"\bdefinitely\b": "likely",
    r"\bclearly\b": "it appears",
}
