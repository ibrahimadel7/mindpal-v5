from __future__ import annotations

import logging
from typing import Any

from app.schemas.analysis import PatternAnalysis
from app.services.llm_service import LLMService

logger = logging.getLogger(__name__)


class AnalysisService:
    """Analyzes behavioral patterns and decides when to surface insights."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.llm = llm_service or LLMService()

    async def analyze_patterns(self, context: dict[str, Any]) -> PatternAnalysis:
        """
        Analyze behavioral patterns from user context.
        
        Args:
            context: Dict containing user_text, emotions, habits, stats, trends, etc.
            
        Returns:
            PatternAnalysis with detected pattern and surface decision.
        """
        analysis_prompt = self._build_analysis_prompt(context)
        
        try:
            result_json = await self.llm.generate_structured_json(
                system_prompt=self._build_analysis_system_prompt(),
                user_prompt=analysis_prompt,
                max_tokens=400,
            )
            analysis = PatternAnalysis.model_validate(result_json)
            return analysis
        except Exception as exc:
            logger.warning("Pattern analysis failed: %s", exc)
            # Return neutral analysis on failure
            return PatternAnalysis(
                primary_pattern=None,
                confidence=0.0,
                supporting_signals=[],
                should_surface=False,
            )

    @staticmethod
    def _build_analysis_system_prompt() -> str:
        return (
            "You are a behavioral pattern analyzer. Analyze user context and identify meaningful patterns.\n\n"
            "Return ONLY valid JSON:\n"
            "{\n"
            '  "primary_pattern": "pattern description or null",\n'
            '  "confidence": 0.0-1.0,\n'
            '  "supporting_signals": ["short phrase1", "short phrase2"],\n'
            '  "should_surface": true/false\n'
            "}\n\n"
            "Decision rules:\n"
            "- Only detect patterns if meaningful (repeated, trending, or time-based behavior)\n"
            "- Prefer strong, multi-signal patterns over weak correlations\n"
            "- If weak or unclear → set primary_pattern=null and should_surface=false\n"
            "- Confidence must reflect strength of evidence (0.0-1.0)\n"
            "- Avoid generic statements; focus on specific, actionable observations\n"
            "- Set should_surface=true only if pattern is both strong (confidence>0.6) and meaningful"
        )

    @staticmethod
    def _build_analysis_prompt(context: dict[str, Any]) -> str:
        """Build the analysis prompt from context data."""
        user_text = context.get("user_text", "")
        emotions = context.get("emotions", [])
        habits = context.get("habits", [])
        emotion_stats = context.get("emotion_stats", [])
        habit_stats = context.get("habit_stats", [])
        time_patterns = context.get("time_patterns", [])
        habit_emotion_links = context.get("habit_emotion_links", [])
        graph_signals = context.get("graph_signals", [])

        return (
            f"User message: {user_text}\n\n"
            f"Current emotions: {emotions}\n"
            f"Current habits: {habits}\n\n"
            f"Emotion trends (over time): {emotion_stats}\n"
            f"Habit frequency: {habit_stats}\n"
            f"Time-based patterns: {time_patterns}\n"
            f"Habit-emotion associations: {habit_emotion_links}\n\n"
            f"Additional behavior signals: {graph_signals}\n\n"
            "Analyze for:\n"
            "1. Recurring patterns (same emotions/habits appearing together)\n"
            "2. Time-based patterns (emotions at specific times/days)\n"
            "3. Habit-emotion links (habits that correlate with emotions)\n"
            "4. Escalating trends (increasing frequency or intensity)\n"
            "5. Behavioral cycles (predictable cycles or rhythms)\n\n"
            "Return analysis result."
        )
