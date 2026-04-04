"""Memory Exposure Control system for safe memory usage in responses."""

from __future__ import annotations

import logging
from typing import Any

from app.schemas.memory_exposure import (
    MemoryConfidenceScore,
    MemoryExposureContext,
    MemoryExposureDecision,
    MemoryExposureLevel,
    USER_SIGNAL_CONFIRMATION_KEYWORDS,
    USER_SIGNAL_UNCERTAINTY_KEYWORDS,
)

logger = logging.getLogger(__name__)


class MemoryExposureControl:
    """Controls how and when memory is exposed in responses."""

    def score_memory_confidence(
        self,
        memory_content: str,
        days_since_mention: int,
        mention_count: int,
        is_highly_specific: bool,
        semantic_relevance_to_current: float = 0.5,
    ) -> MemoryConfidenceScore:
        """Score confidence of a memory for usage."""
        # Recency scoring
        if days_since_mention < 7:
            recency_score = 1.0
        elif days_since_mention < 14:
            recency_score = 0.8
        elif days_since_mention < 30:
            recency_score = 0.6
        elif days_since_mention < 90:
            recency_score = 0.4
        else:
            recency_score = 0.2

        # Frequency scoring
        if mention_count == 1:
            frequency_score = 0.4
        elif mention_count == 2:
            frequency_score = 0.6
        elif mention_count >= 3:
            frequency_score = 0.9
        else:
            frequency_score = 0.0

        # Specificity as relevance to current context
        specificity_score = semantic_relevance_to_current

        return MemoryConfidenceScore(
            memory_content=memory_content,
            recency_score=recency_score,
            frequency_score=frequency_score,
            specificity_score=specificity_score,
            is_highly_specific=is_highly_specific,
            days_since_mention=days_since_mention,
            mention_count=mention_count,
        )

    def detect_user_uncertainty(self, user_text: str) -> bool:
        """Detect if user expressed uncertainty."""
        lowered = user_text.lower()
        return any(keyword in lowered for keyword in USER_SIGNAL_UNCERTAINTY_KEYWORDS)

    def detect_user_confirmation(self, user_text: str) -> bool:
        """Detect if user confirmed/agreed with a direction."""
        lowered = user_text.lower()
        return any(keyword in lowered for keyword in USER_SIGNAL_CONFIRMATION_KEYWORDS)

    def determine_exposure_level(
        self,
        memory: MemoryConfidenceScore,
        context: MemoryExposureContext,
    ) -> MemoryExposureDecision:
        """Determine safe memory exposure level."""
        level = MemoryExposureLevel.HIDDEN
        justifications = []
        
        # Calculate confidence early for use in all paths
        confidence = memory.combined_confidence

        # Rule 1: Never expose explicitly on turn <= 2
        if context.turn_number <= 2:
            justifications.append("Early conversation (turn ≤ 2)")
            return MemoryExposureDecision(
                exposure_level=level,
                should_include_memory=False,
                justification=" | ".join(justifications),
                confidence_score=confidence,
            )

        # Rule 2: Confidence gates (check user signals first)
        # Rule 2a: Check user signals first (can unlock even low confidence)
        if context.user_expressed_uncertainty:
            if confidence >= 0.45:
                level = MemoryExposureLevel.SOFT_RECALL
                justifications.append("User expressed uncertainty (unlocks soft recall)")
            else:
                justifications.append(f"Low confidence ({confidence:.2f}) with uncertainty noted")
                return MemoryExposureDecision(
                    exposure_level=level,
                    should_include_memory=False,
                    justification=" | ".join(justifications),
                    confidence_score=confidence,
                )
        elif confidence < 0.50:
            justifications.append(f"Low confidence ({confidence:.2f} < 0.50)")
            return MemoryExposureDecision(
                exposure_level=level,
                should_include_memory=False,
                justification=" | ".join(justifications),
                confidence_score=confidence,
            )

        # Rule 2b: Standard confidence thresholds
        if confidence < 0.70 and level == MemoryExposureLevel.HIDDEN:
            level = MemoryExposureLevel.SOFT_RECALL
            justifications.append(f"Medium confidence ({confidence:.2f})")
        elif confidence >= 0.70:
            level = MemoryExposureLevel.EXPLICIT_RECALL
            justifications.append(f"High confidence ({confidence:.2f})")

        # Rule 3: User confirmation can unlock explicit recall
        if context.user_confirmed_direction:
            if level in (MemoryExposureLevel.SOFT_RECALL, MemoryExposureLevel.EXPLICIT_RECALL):
                level = MemoryExposureLevel.EXPLICIT_RECALL
                justifications.append("User confirmed direction (unlocks explicit)")

        # Rule 4: Enforce gradual escalation
        if context.escalation_turns < 2 and level == MemoryExposureLevel.EXPLICIT_RECALL:
            level = MemoryExposureLevel.SOFT_RECALL
            justifications.append("Requires gradual escalation (demoted to soft)")

        # Rule 5: Highly specific memories can't be explicit unless user mentioned them
        if memory.is_highly_specific and not context.memory_was_user_mentioned:
            if level == MemoryExposureLevel.EXPLICIT_RECALL:
                level = MemoryExposureLevel.SOFT_RECALL
                justifications.append("Highly specific memory (not user-mentioned → soft)")

        # Determine if we should use memory at all
        should_include = level != MemoryExposureLevel.HIDDEN

        # Map level to reference style
        if level == MemoryExposureLevel.HIDDEN:
            reference_style = "none"
        elif level == MemoryExposureLevel.SOFT_RECALL:
            reference_style = "indirect"
        else:
            reference_style = "direct"

        return MemoryExposureDecision(
            exposure_level=level,
            should_include_memory=should_include,
            memory_reference_style=reference_style,
            justification=" | ".join(justifications) if justifications else "Default hidden",
            confidence_score=confidence,
        )

    def apply_exposure_constraints(
        self, 
        decision: MemoryExposureDecision,
        generation_context: dict[str, Any],
    ) -> dict[str, Any]:
        """Apply exposure constraints to generation context."""
        if decision.exposure_level == MemoryExposureLevel.HIDDEN:
            # Use memory internally only, don't mention it
            generation_context["memory_mention"] = None
            generation_context["tone_guidance"] = "informed by past patterns"
            generation_context["include_memory_reference"] = False
            
        elif decision.exposure_level == MemoryExposureLevel.SOFT_RECALL:
            # Hint at memory with general language
            generation_context["memory_mention"] = "soft_reference"
            generation_context["tone_guidance"] = "with gentle recognition of patterns"
            generation_context["include_memory_reference"] = False
            generation_context["use_hedging"] = True
            
        elif decision.exposure_level == MemoryExposureLevel.EXPLICIT_RECALL:
            # Can reference memory directly
            generation_context["memory_mention"] = "explicit_reference"
            generation_context["tone_guidance"] = "with recognition of shared history"
            generation_context["include_memory_reference"] = True
            generation_context["use_hedging"] = False

        generation_context["exposure_decision"] = decision
        return generation_context
