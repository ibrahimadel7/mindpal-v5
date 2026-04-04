from __future__ import annotations

import unittest

from app.rag.pipeline import RAGPipeline


class RagPromptTests(unittest.TestCase):
    def test_prompt_includes_associations_and_non_causal_guidance(self):
        pipeline = object.__new__(RAGPipeline)

        prompt = pipeline._build_prompt(
            user_text="I keep feeling anxious at night.",
            history_block="user: I feel stressed\nassistant: Thanks for sharing",
            cross_conversation_history_block="conv#3 2026-03-09T21:00:00 user: I felt anxious before bed",
            similar_messages=["past sample"],
            kb_docs=["kb sample"],
            kb_entries=[
                {
                    "content": "Try a 2-minute grounding exercise before sleep.",
                    "metadata": {"title": "Sleep Grounding", "category": "coping", "tags": "sleep,stress"},
                }
            ],
            emotion_stats=[{"label": "anxiety", "count": 4}],
            habit_stats=[{"habit": "procrastinating", "count": 3}],
            time_patterns=[{"hour_of_day": 22, "top_emotion": "anxiety", "message_count": 2}],
            habit_emotion_links=[
                {
                    "habit": "procrastinating",
                    "emotion": "anxiety",
                    "co_occurrence": 2,
                    "habit_total": 3,
                    "link_strength": 0.6667,
                }
            ],
            recent_memories=["The user has been struggling with nighttime anxiety and wants steadier sleep routines."],
            emotions=[{"label": "anxiety", "confidence": 0.82}],
            habits=[{"habit": "procrastinating", "confidence": 0.71}],
            recall_intent=True,
            supportive_mode=True,
        )

        self.assertIn("User history across conversations (same user only)", prompt)
        self.assertIn("Do NOT presume without being asked", prompt)
        self.assertIn("Plan type: history_recall", prompt)
        self.assertIn("Target:", prompt)
        self.assertIn("Do NOT make speculative guesses about causes or feelings", prompt)

    def test_prompt_omits_cross_conversation_history_when_not_recall(self):
        pipeline = object.__new__(RAGPipeline)

        prompt = pipeline._build_prompt(
            user_text="Hi there",
            history_block="user: hi",
            cross_conversation_history_block="conv#2 user: old message",
            similar_messages=["past sample"],
            kb_docs=["kb sample"],
            kb_entries=[],
            emotion_stats=[{"label": "neutral", "count": 1}],
            habit_stats=[],
            time_patterns=[],
            habit_emotion_links=[],
            recent_memories=[],
            emotions=[{"label": "neutral", "confidence": 0.7}],
            habits=[],
            recall_intent=False,
            supportive_mode=False,
        )

        self.assertNotIn("User history across conversations (same user only)", prompt)

    def test_small_talk_detector(self):
        pipeline = object.__new__(RAGPipeline)

        self.assertTrue(pipeline._is_small_talk_message("Hi"))
        self.assertTrue(pipeline._is_small_talk_message("thanks!"))
        self.assertFalse(pipeline._is_small_talk_message("I am stressed and need help"))

    def test_distress_detector_uses_emotions_or_text(self):
        pipeline = object.__new__(RAGPipeline)

        self.assertTrue(pipeline._needs_distress_support("I feel fine", [{"label": "anxiety", "confidence": 0.8}]))
        self.assertTrue(pipeline._needs_distress_support("I feel overwhelmed right now", [{"label": "neutral", "confidence": 0.9}]))
        self.assertFalse(pipeline._needs_distress_support("I had coffee", [{"label": "neutral", "confidence": 0.9}]))

    def test_history_recall_intent_detection(self):
        pipeline = object.__new__(RAGPipeline)

        self.assertTrue(pipeline._is_history_recall_query("What did I say before about sleep?"))
        self.assertTrue(pipeline._is_history_recall_query("Have we talked about burnout earlier?"))
        self.assertFalse(pipeline._is_history_recall_query("Give me one grounding exercise for tonight."))

    def test_response_planner_prefers_short_reply_for_small_talk(self):
        pipeline = object.__new__(RAGPipeline)

        plan = pipeline._plan_response(
            user_text="Hi",
            emotions=[{"label": "neutral", "confidence": 0.6}],
            habits=[],
            recall_intent=False,
            supportive_mode=False,
        )

        self.assertEqual(plan.label, "small_talk")
        self.assertEqual(plan.min_sentences, 1)
        self.assertEqual(plan.max_sentences, 1)
        self.assertEqual(plan.max_tokens, 48)
        self.assertFalse(plan.ask_follow_up)

    def test_response_planner_prefers_supportive_reply_for_distress(self):
        pipeline = object.__new__(RAGPipeline)

        plan = pipeline._plan_response(
            user_text="I feel overwhelmed and anxious tonight.",
            emotions=[{"label": "anxiety", "confidence": 0.84}],
            habits=[],
            recall_intent=False,
            supportive_mode=True,
        )

        self.assertEqual(plan.label, "supportive_reflection")
        self.assertEqual(plan.min_sentences, 2)
        self.assertEqual(plan.max_sentences, 3)
        self.assertFalse(plan.ask_follow_up)
        self.assertFalse(plan.use_bullets)

    def test_response_planner_prefers_structured_explanation_for_multi_part_request(self):
        pipeline = object.__new__(RAGPipeline)

        plan = pipeline._plan_response(
            user_text="Can you explain what happened and also what I should do next?",
            emotions=[{"label": "neutral", "confidence": 0.7}],
            habits=[{"habit": "procrastinating", "confidence": 0.6}],
            recall_intent=False,
            supportive_mode=False,
        )

        self.assertEqual(plan.label, "structured_explanation")
        self.assertTrue(plan.use_bullets)
        self.assertEqual(plan.max_tokens, 180)


if __name__ == "__main__":
    unittest.main()
