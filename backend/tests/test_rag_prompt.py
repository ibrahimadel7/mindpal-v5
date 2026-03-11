from __future__ import annotations

import unittest

from app.rag.pipeline import RAGPipeline


class RagPromptTests(unittest.TestCase):
    def test_prompt_includes_associations_and_non_causal_guidance(self):
        pipeline = object.__new__(RAGPipeline)

        prompt = pipeline._build_prompt(
            user_text="I keep feeling anxious at night.",
            history_block="user: I feel stressed\nassistant: Thanks for sharing",
            similar_messages=["past sample"],
            kb_docs=["kb sample"],
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
            emotions=[{"label": "anxiety", "confidence": 0.82}],
            habits=[{"habit": "procrastinating", "confidence": 0.71}],
        )

        self.assertIn("Habit-emotion associations (historical co-occurrence, not causation)", prompt)
        self.assertIn("Use current detections first", prompt)
        self.assertIn("Do not present associations as medical or causal conclusions", prompt)


if __name__ == "__main__":
    unittest.main()
