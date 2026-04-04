from __future__ import annotations

import unittest

from app.services.thinking_service import ThinkingService


class _FakeLLMSuccess:
    async def generate_structured_json(self, system_prompt: str, user_prompt: str, *, temperature: float = 0.0, max_tokens: int = 400):
        return {
            "emotion": "stress",
            "emotion_confidence": 0.74,
            "hypotheses": [
                {"cause": "Deadlines are clustering this week", "confidence": 0.71, "evidence": "mentions pressure repeatedly"},
                {"cause": "Sleep quality may be lower", "confidence": 0.49, "evidence": "late-night pattern"},
            ],
            "missing_information": ["when stress peaks", "what trigger is most recent"],
            "next_best_action": "ask_question",
            "response_focus": "Offer one tentative cause and ask one narrowing question.",
            "should_reference_memory": True,
        }


class _FakeLLMInvalid:
    async def generate_structured_json(self, system_prompt: str, user_prompt: str, *, temperature: float = 0.0, max_tokens: int = 400):
        return {"invalid": "shape"}


class ThinkingServiceTests(unittest.IsolatedAsyncioTestCase):
    async def test_reason_returns_normalized_structured_output(self) -> None:
        service = ThinkingService(llm_service=_FakeLLMSuccess())

        result = await service.reason(
            user_text="I feel stressed this week.",
            conversation_context="User: I have deadlines.",
            memory_context=["Stress around deadlines appeared twice this month."],
            emotions=[{"label": "stress", "confidence": 0.8}],
            habits=[],
            recall_intent=False,
            supportive_mode=True,
        )

        self.assertEqual(result.emotion, "stress")
        self.assertEqual(result.next_best_action, "ask_question")
        self.assertEqual(len(result.hypotheses), 2)
        self.assertGreaterEqual(result.hypotheses[0].confidence, result.hypotheses[1].confidence)
        # Reference requires a higher-confidence leading hypothesis.
        self.assertTrue(result.should_reference_memory)

    async def test_reason_uses_safe_fallback_on_invalid_json_shape(self) -> None:
        service = ThinkingService(llm_service=_FakeLLMInvalid())

        result = await service.reason(
            user_text="Can we look at what happened before?",
            conversation_context="",
            memory_context=[],
            emotions=[{"label": "neutral", "confidence": 0.7}],
            habits=[],
            recall_intent=True,
            supportive_mode=False,
        )

        self.assertEqual(result.next_best_action, "ask_question")
        self.assertEqual(result.emotion, "reflective")
        self.assertFalse(result.should_reference_memory)


if __name__ == "__main__":
    unittest.main()
