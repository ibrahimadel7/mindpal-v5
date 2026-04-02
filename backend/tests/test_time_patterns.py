from __future__ import annotations

from datetime import date, datetime
import unittest

from app.analytics.time_patterns import TimePatternAnalytics


class _ScalarWrapper:
    def __init__(self, values):
        self._values = values

    def all(self):
        return self._values


class _Result:
    def __init__(self, rows=None, scalars=None):
        self._rows = rows or []
        self._scalars = scalars or []

    def all(self):
        return self._rows

    def scalars(self):
        return _ScalarWrapper(self._scalars)


class _FakeDB:
    def __init__(self, results):
        self._results = list(results)

    async def execute(self, _query):
        if not self._results:
            raise AssertionError("No result prepared for execute()")
        return self._results.pop(0)


class TimePatternAnalyticsTests(unittest.IsolatedAsyncioTestCase):
    async def test_habit_stats_merges_chat_and_checklist_completions(self):
        analytics = TimePatternAnalytics()

        habit_rows = [
            {"habits": [{"habit": "Procrastinating"}]},
            {"habits": [{"habit": "Doomscrolling"}, {"habit": "Procrastinating"}]},
        ]
        completed_habits = ["Procrastinating", "Hydration"]

        db = _FakeDB([
            _Result(scalars=habit_rows),
            _Result(scalars=completed_habits),
        ])

        stats = await analytics.habit_stats(db, user_id=1)
        self.assertEqual(
            stats,
            [
                {"habit": "procrastinating", "count": 3},
                {"habit": "doomscrolling", "count": 1},
                {"habit": "hydration", "count": 1},
            ],
        )

    async def test_overview_metrics_and_daily_trends_are_user_scoped_shapes(self):
        analytics = TimePatternAnalytics()

        rows = [
            (
                datetime(2026, 3, 9, 9, 0),
                {"emotions": [{"label": "Anxiety"}, {"label": "Stress"}]},
                {"habits": [{"habit": "Procrastinating"}]},
            ),
            (
                datetime(2026, 3, 9, 14, 0),
                {"emotions": [{"label": "Anxiety"}]},
                {"habits": [{"habit": "Doomscrolling"}]},
            ),
            (
                datetime(2026, 3, 10, 20, 0),
                {"emotions": [{"label": "Sadness"}]},
                {"habits": [{"habit": "Procrastinating"}]},
            ),
        ]

        db = _FakeDB([
            _Result(rows=rows),  # overview
            _Result(scalars=["Procrastinating", "Journaling"]),  # completed checklist habits for overview
            _Result(rows=[(r[0], r[1]) for r in rows]),  # daily emotion trends
            _Result(rows=[(r[0], r[2]) for r in rows]),  # daily habit trends
            _Result(rows=[(date(2026, 3, 10), "Journaling")]),  # completed checklist habits for trend
        ])

        overview = await analytics.overview_metrics(db, user_id=1)
        emotion_trends = await analytics.daily_emotion_trends(db, user_id=1)
        habit_trends = await analytics.daily_habit_trends(db, user_id=1)

        self.assertEqual(overview["total_messages"], 3)
        self.assertEqual(overview["active_days"], 2)
        self.assertEqual(overview["dominant_emotion"], "anxiety")
        self.assertEqual(overview["dominant_habit"], "procrastinating")

        self.assertEqual([row["date"] for row in emotion_trends], ["2026-03-09", "2026-03-10"])
        self.assertEqual(emotion_trends[0]["total"], 3)
        self.assertEqual(emotion_trends[1]["total"], 1)

        self.assertEqual([row["date"] for row in habit_trends], ["2026-03-09", "2026-03-10"])
        self.assertEqual(habit_trends[0]["total"], 2)
        self.assertEqual(habit_trends[1]["total"], 2)
        day_two_habits = {item["habit"]: item["count"] for item in habit_trends[1]["habits"]}
        self.assertEqual(day_two_habits.get("journaling"), 1)
        self.assertEqual(day_two_habits.get("procrastinating"), 1)

    async def test_habit_emotion_links_computes_strength_and_threshold(self):
        analytics = TimePatternAnalytics()

        rows = [
            (
                {"emotions": [{"label": "Anxiety"}, {"label": "Stress"}]},
                {"habits": [{"habit": "Procrastinating"}]},
            ),
            (
                {"emotions": [{"label": "Anxiety"}]},
                {"habits": [{"habit": "Procrastinating"}, {"habit": "Doomscrolling"}]},
            ),
            (
                {"emotions": [{"label": "Sadness"}]},
                {"habits": [{"habit": "Doomscrolling"}]},
            ),
        ]

        db = _FakeDB([_Result(rows=rows), _Result(rows=rows)])

        all_links = await analytics.habit_emotion_links(db, user_id=1, min_count=1, top_n=10)
        filtered_links = await analytics.habit_emotion_links(db, user_id=1, min_count=2, top_n=10)

        top = all_links[0]
        self.assertEqual(top["habit"], "procrastinating")
        self.assertEqual(top["emotion"], "anxiety")
        self.assertEqual(top["co_occurrence"], 2)
        self.assertEqual(top["habit_total"], 2)
        self.assertEqual(top["link_strength"], 1.0)

        self.assertEqual(len(filtered_links), 1)
        self.assertEqual(filtered_links[0]["co_occurrence"], 2)


if __name__ == "__main__":
    unittest.main()
