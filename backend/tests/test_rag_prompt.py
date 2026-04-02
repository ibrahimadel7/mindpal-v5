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

        self.assertIn("User memories", prompt)
        self.assertIn("Habit-emotion associations (historical co-occurrence, not causation)", prompt)
        self.assertIn("Use current detections first", prompt)
        self.assertIn("Do not present associations as medical or causal conclusions", prompt)
        self.assertIn("Knowledge base context", prompt)
        self.assertIn("Do NOT provide clinical diagnosis", prompt)
        self.assertIn("User history across conversations (same user only)", prompt)
        self.assertIn("Summarize findings unless the user explicitly asks for direct quotes or timestamps", prompt)
        self.assertIn("Default: 1-3 sentences", prompt)

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


if __name__ == "__main__":
    unittest.main()
