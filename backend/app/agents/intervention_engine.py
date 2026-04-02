from __future__ import annotations

from datetime import datetime, timedelta

from app.schemas.analysis import PatternAnalysis


class InterventionControl:
    """Controls when and how to surface detected patterns to users."""

    # Minimum messages between interventions
    MIN_MESSAGE_COUNT = 5
    # Minimum confidence threshold
    MIN_CONFIDENCE = 0.6
    # Cooldown period between interventions (in hours)
    INTERVENTION_COOLDOWN_HOURS = 2

    @staticmethod
    def should_intervene(
        analysis: PatternAnalysis,
        last_intervention_at: datetime | None,
        message_count_since_last: int,
        user_state: str | None = None,
    ) -> bool:
        """
        Decide whether to surface a detected pattern.
        
        Args:
            analysis: PatternAnalysis result
            last_intervention_at: When the last intervention surfaced
            message_count_since_last: Messages sent since last intervention
            user_state: Optional user state indicator (e.g., "overwhelmed")
            
        Returns:
            True if intervention should be surfaced, False otherwise.
        """
        # Do NOT intervene if analysis says no
        if not analysis.should_surface:
            return False

        # Do NOT intervene if confidence is too low
        if analysis.confidence < InterventionControl.MIN_CONFIDENCE:
            return False

        # Do NOT intervene if user is overwhelmed
        if user_state and user_state.lower() == "overwhelmed":
            return False

        # Do NOT intervene if not enough messages have passed
        if message_count_since_last < InterventionControl.MIN_MESSAGE_COUNT:
            return False

        # Do NOT intervene if still in cooldown period
        if last_intervention_at is not None:
            time_since = datetime.utcnow() - last_intervention_at
            if time_since < timedelta(hours=InterventionControl.INTERVENTION_COOLDOWN_HOURS):
                return False

        # All checks passed
        return True

    @staticmethod
    def build_intervention_injection(analysis: PatternAnalysis) -> str:
        """
        Build the text to inject into the main prompt if intervention is approved.
        
        Args:
            analysis: PatternAnalysis result
            
        Returns:
            Prompt injection text to add to main chat prompt.
        """
        if not analysis.primary_pattern:
            return ""

        signals_text = ", ".join(analysis.supporting_signals) if analysis.supporting_signals else "pattern signals"
        confidence_pct = int(analysis.confidence * 100)

        return (
            f"\n--- Internal Pattern Detection (confidence: {confidence_pct}%) ---\n"
            f"Pattern: {analysis.primary_pattern}\n"
            f"Signals: {signals_text}\n"
            f"\nIf relevant, gently reflect this pattern using uncertain language "
            f'(e.g., "it seems like", "I might be wrong", "I wonder if"). '
            f"Do NOT state it as a fact or diagnosis."
        )
