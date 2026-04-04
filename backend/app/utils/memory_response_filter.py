"""Response filter to remove creepy/invasive language and reduce memory exposure."""

from __future__ import annotations

import logging
import re
from typing import Any

from app.schemas.memory_exposure import (
    BLOCKED_DATA_EXPOSURE_PHRASES,
    OVERCONFIDENT_REPLACEMENTS,
    ResponseFilterResult,
)

logger = logging.getLogger(__name__)


class MemoryResponseFilter:
    """Filters responses to ensure memory is used appropriately and naturally."""

    def filter_response(
        self,
        response: str,
        turn_number: int,
        confidence_score: float,
        exposure_level: str,
    ) -> ResponseFilterResult:
        """Apply all filter rules to response.
        
        Args:
            response: Generated response text
            turn_number: Current conversation turn
            confidence_score: Memory confidence (0-1)
            exposure_level: exposure level used
        
        Returns:
            ResponseFilterResult with filtered response
        """
        original = response
        filters_applied: list[str] = []
        improvements: dict[str, str] = {}

        # Rule 1: Remove data exposure phrases
        response, rule1_applied = self._remove_data_exposure_phrases(response)
        if rule1_applied:
            filters_applied.append("removed_data_exposure_phrases")

        # Rule 2: Detect and generalize early specificity
        if turn_number <= 3:
            response, rule2_applied = self._generalize_early_specificity(response)
            if rule2_applied:
                filters_applied.append("generalized_early_specificity")

        # Rule 3: Soften overconfident language
        response, rule3_count = self._soften_overconfident_claims(response)
        if rule3_count > 0:
            filters_applied.append(f"softened_overconfidence_({rule3_count}x)")
            improvements["overconfidence"] = f"softened {rule3_count} claims"

        # Rule 4: Limit emotional elements
        emotional_density = self._count_emotional_elements(response)
        if emotional_density > 2:
            response = self._trim_emotional_elements(response)
            filters_applied.append("trimmed_emotional_density")
            improvements["emotional_density"] = f"reduced from {emotional_density} to 2"

        # Rule 5: Check specificity score
        specificity = self._calculate_specificity_score(response)
        if specificity > 0.15 and turn_number < 3:
            response = self._make_more_general(response)
            filters_applied.append("reduced_specificity")
            improvements["specificity"] = f"reduced from {specificity:.2f} to acceptable"

        # Rule 6: Ensure uncertainty language is present for medium confidence
        if 0.5 <= confidence_score < 0.75 and not self._has_uncertainty_language(response):
            response = self._add_uncertainty_framing(response)
            filters_applied.append("added_uncertainty_language")

        return ResponseFilterResult(
            original_response=original,
            filtered_response=response.strip(),
            filters_applied=filters_applied,
            specificity_score=specificity,
            emotional_density=emotional_density,
            improvements_made=improvements,
        )

    @staticmethod
    def _remove_data_exposure_phrases(text: str) -> tuple[str, bool]:
        """Remove phrases that expose internal data processing."""
        original_length = len(text)
        
        for phrase in BLOCKED_DATA_EXPOSURE_PHRASES:
            text = re.sub(
                re.escape(phrase),
                "",
                text,
                flags=re.IGNORECASE,
            )
        
        # Clean up extra spaces
        text = re.sub(r"\s+", " ", text).strip()
        
        was_modified = len(text) < original_length
        return text, was_modified

    @staticmethod
    def _generalize_early_specificity(text: str) -> tuple[str, bool]:
        """Generalize overly specific references in early conversation."""
        original = text
        
        # Pattern: "your X with Y" → "sometimes" version
        text = re.sub(
            r"your (\w+) with (\w+|\w+ \w+)",
            r"when \1 comes up",
            text,
            flags=re.IGNORECASE,
        )
        
        # Pattern: specific dates → vague time markers
        text = re.sub(
            r"(last|this) (week|month|week|day)",
            "recently",
            text,
            flags=re.IGNORECASE,
        )
        
        # Pattern: "you always" → "sometimes you"
        text = re.sub(
            r"you always (\w+)",
            r"sometimes you \1",
            text,
            flags=re.IGNORECASE,
        )
        
        was_modified = text != original
        return text, was_modified

    @staticmethod
    def _soften_overconfident_claims(text: str) -> tuple[str, int]:
        """Soften overconfident language in response."""
        count = 0
        
        for pattern, replacement in OVERCONFIDENT_REPLACEMENTS.items():
            new_text, num_subs = re.subn(
                pattern,
                replacement,
                text,
                flags=re.IGNORECASE,
            )
            if num_subs > 0:
                text = new_text
                count += num_subs
        
        return text, count

    @staticmethod
    def _count_emotional_elements(text: str) -> int:
        """Count emotional/insight elements in response."""
        count = 0
        
        # Emotional acknowledgments
        if any(phrase in text.lower() for phrase in [
            "i understand", "i hear you", "that sounds",
            "must be", "feel", "overwhelm", "difficult"
        ]):
            count += 1
        
        # Memory/history references
        if any(phrase in text.lower() for phrase in [
            "remember", "before", "pattern", "used to", "similar"
        ]):
            count += 1
        
        # Questions/prompts
        if "?" in text:
            count += 1
        
        # Actionable suggestions
        if any(phrase in text.lower() for phrase in [
            "try", "consider", "might help", "could", "suggest"
        ]):
            count += 1
        
        return count

    @staticmethod
    def _trim_emotional_elements(text: str) -> str:
        """Remove or shorten surplus emotional/insight elements."""
        sentences = text.split(". ")
        if len(sentences) <= 2:
            return text
        
        # Keep first (acknowledgment) and last (action) sentences
        # Skip middle tangential ones
        kept = [sentences[0], sentences[-1]]
        return ". ".join(kept).strip() + "."

    @staticmethod
    def _calculate_specificity_score(text: str) -> float:
        """Calculate how specific/personal the response is.
        
        Higher = more specific names, dates, events
        """
        total_words = len(text.split())
        if total_words == 0:
            return 0.0
        
        specific_markers = 0
        
        # Proper nouns (rough heuristic)
        proper_nouns = len(re.findall(r"\b[A-Z][a-z]+(?:\s[A-Z][a-z]+)*\b", text))
        specific_markers += proper_nouns * 2
        
        # Dates
        date_patterns = len(re.findall(r"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}", text))
        specific_markers += date_patterns * 3
        
        # Possessive references to past
        past_refs = len(re.findall(r"your \w+ (with|from|about)", text, re.IGNORECASE))
        specific_markers += past_refs * 2
        
        return min(specific_markers / total_words, 1.0)

    @staticmethod
    def _make_more_general(text: str) -> str:
        """Generalize specific language."""
        # Replace specific references with general ones
        generalizations = {
            r"When you (\w+)": r"When feelings like that come up",
            r"Your (\w+) (?:with|about) (\w+)": r"When \1 feels heavy",
            r"that time you": "before",
            r"compared to last": "compared to",
        }
        
        for pattern, replacement in generalizations.items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
        
        return text

    @staticmethod
    def _has_uncertainty_language(text: str) -> bool:
        """Check if response contains uncertainty language."""
        uncertainty_words = {
            "might", "could", "seems", "appears",
            "potentially", "perhaps", "maybe", "may be",
            "i might", "could be", "it seems"
        }
        lowered = text.lower()
        return any(word in lowered for word in uncertainty_words)

    @staticmethod
    def _add_uncertainty_framing(text: str) -> str:
        """Prepend uncertainty framing if missing."""
        if text.strip().startswith(("I", "The", "This", "Maybe", "Sometimes")):
            # Add uncertainty to first sentence
            sentences = text.split(". ")
            if sentences:
                first = sentences[0]
                if not any(word in first.lower() for word in ["might", "could", "seems"]):
                    first = f"It seems like {first[0].lower() + first[1:] if len(first) > 1 else first}"
                    sentences[0] = first
                    text = ". ".join(sentences)
        
        return text
