from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class HypothesisItem(BaseModel):
    cause: str = Field(min_length=1, max_length=240)
    confidence: float = Field(ge=0.0, le=1.0)
    evidence: str | None = Field(default=None, max_length=280)


class ReasoningOutput(BaseModel):
    """Internal structured reasoning output used to condition the final response."""

    emotion: str = Field(default="uncertain", min_length=1, max_length=64)
    emotion_confidence: float = Field(default=0.0, ge=0.0, le=1.0)
    hypotheses: list[HypothesisItem] = Field(default_factory=list, max_length=3)
    missing_information: list[str] = Field(default_factory=list, max_length=3)
    next_best_action: Literal["ask_question", "propose_hypothesis", "validate"] = "ask_question"
    response_focus: str = Field(default="Ask one focused follow-up question.", min_length=1, max_length=220)
    should_reference_memory: bool = False


DEFAULT_REASONING = ReasoningOutput(
    emotion="uncertain",
    emotion_confidence=0.0,
    hypotheses=[],
    missing_information=["trigger context"],
    next_best_action="ask_question",
    response_focus="Ask one focused follow-up question to reduce ambiguity.",
    should_reference_memory=False,
)
