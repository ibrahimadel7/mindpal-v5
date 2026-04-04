from __future__ import annotations

import logging
from typing import Any

from app.schemas.thinking import DEFAULT_REASONING, HypothesisItem, ReasoningOutput
from app.services.llm_service import LLMService

logger = logging.getLogger(__name__)


class ThinkingService:
    """Builds structured internal reasoning for response conditioning."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.llm = llm_service or LLMService()

    async def reason(
        self,
        *,
        user_text: str,
        conversation_context: str,
        memory_context: list[str],
        emotions: list[dict[str, Any]],
        habits: list[dict[str, Any]],
        recall_intent: bool,
        supportive_mode: bool,
    ) -> ReasoningOutput:
        system_prompt = (
            "You are an internal reasoning module for a mental-health reflection assistant. "
            "Analyze the user's message to infer their emotional state and context. "
            "Be conservative - only propose hypotheses when there is clear evidence. "
            "Never diagnose. Never state uncertain causes as facts. "
            "If unclear, suggest asking a clarifying question instead of guessing. "
            "Return strict JSON only."
        )
        user_prompt = (
            "Return a JSON object with keys exactly: "
            "emotion, emotion_confidence, hypotheses, missing_information, next_best_action, response_focus, should_reference_memory.\n\n"
            "Constraints:\n"
            "- hypotheses: at most 3 items, sorted by confidence desc. Only include if confidence >= 0.55\n"
            "- each hypothesis item keys: cause, confidence, evidence\n"
            "- confidence values are 0..1\n"
            "- missing_information: at most 3 short strings - what context would help understand the situation better\n"
            "- next_best_action: ask_question (if unclear), propose_hypothesis (if confident + relevant), or validate (if clear + acknowledge)\n"
            "- Only set should_reference_memory=true if a memory is highly relevant (confidence >= 0.65) and would genuinely help\n"
            "- If unsure about anything, prefer ask_question over proposing hypotheses\n\n"
            f"User message:\n{user_text}\n\n"
            f"Conversation context:\n{conversation_context or '- none'}\n\n"
            f"Memory context:\n{self._format_memory(memory_context)}\n\n"
            f"Detected emotions:\n{emotions}\n\n"
            f"Detected habits:\n{habits}\n\n"
            f"Flags: recall_intent={recall_intent}, supportive_mode={supportive_mode}"
        )

        try:
            raw = await self.llm.generate_structured_json(
                system_prompt,
                user_prompt,
                temperature=0.1,
                max_tokens=320,
            )
            required_keys = {
                "emotion",
                "emotion_confidence",
                "hypotheses",
                "missing_information",
                "next_best_action",
                "response_focus",
            }
            if not isinstance(raw, dict) or not required_keys.issubset(raw.keys()):
                raise ValueError("Reasoning JSON missing required keys")
            output = ReasoningOutput.model_validate(raw)
            return self._normalize(output)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Thinking layer fallback used due to reasoning failure: %s", exc)
            return self._fallback(
                user_text=user_text,
                emotions=emotions,
                habits=habits,
                recall_intent=recall_intent,
                supportive_mode=supportive_mode,
            )

    @staticmethod
    def _format_memory(memory_context: list[str]) -> str:
        if not memory_context:
            return "- none"
        return "\n".join(f"- {item}" for item in memory_context[:4] if item.strip()) or "- none"

    @staticmethod
    def _normalize(output: ReasoningOutput) -> ReasoningOutput:
        hypotheses = sorted(output.hypotheses, key=lambda item: item.confidence, reverse=True)[:3]
        missing = [item.strip() for item in output.missing_information if item.strip()][:3]

        if output.next_best_action == "ask_question" and not missing:
            missing = ["trigger context"]

        should_reference_memory = output.should_reference_memory and (hypotheses[0].confidence >= 0.65 if hypotheses else False)

        return ReasoningOutput(
            emotion=output.emotion.strip() or "uncertain",
            emotion_confidence=max(0.0, min(float(output.emotion_confidence), 1.0)),
            hypotheses=[
                HypothesisItem(
                    cause=item.cause.strip()[:240] or "unclear cause",
                    confidence=max(0.0, min(float(item.confidence), 1.0)),
                    evidence=(item.evidence.strip()[:280] if item.evidence else None),
                )
                for item in hypotheses
            ],
            missing_information=missing,
            next_best_action=output.next_best_action,
            response_focus=output.response_focus.strip()[:220] or "Ask one focused follow-up question.",
            should_reference_memory=should_reference_memory,
        )

    @staticmethod
    def _fallback(
        *,
        user_text: str,
        emotions: list[dict[str, Any]],
        habits: list[dict[str, Any]],
        recall_intent: bool,
        supportive_mode: bool,
    ) -> ReasoningOutput:
        lowered = user_text.lower()

        if recall_intent:
            return ReasoningOutput(
                emotion="reflective",
                emotion_confidence=0.55,
                hypotheses=[
                    HypothesisItem(cause="User wants to recall or reference past conversations.", confidence=0.62, evidence="history recall wording")
                ],
                missing_information=["which period or topic to focus on"],
                next_best_action="ask_question",
                response_focus="Clarify what part of their history would be helpful to review.",
                should_reference_memory=False,
            )

        if supportive_mode:
            return ReasoningOutput(
                emotion="distress",
                emotion_confidence=0.58,
                hypotheses=[],
                missing_information=["what's specifically bothering them right now"],
                next_best_action="ask_question",
                response_focus="Ask what's on their mind.",
                should_reference_memory=False,
            )

        if "stress" in lowered or "anx" in lowered:
            return ReasoningOutput(
                emotion="stressed",
                emotion_confidence=0.6,
                hypotheses=[
                    HypothesisItem(cause="Mentioned stress or anxiety.", confidence=0.60, evidence="explicit keyword")
                ],
                missing_information=["what's causing the most pressure"],
                next_best_action="ask_question",
                response_focus="Ask what's contributing most to the stress.",
                should_reference_memory=False,
            )

        if habits:
            return ReasoningOutput(
                emotion="neutral",
                emotion_confidence=0.5,
                hypotheses=[],
                missing_information=["whether habits are relevant to current concern"],
                next_best_action="ask_question",
                response_focus="Acknowledge and ask if habits are related.",
                should_reference_memory=False,
            )

        return DEFAULT_REASONING
