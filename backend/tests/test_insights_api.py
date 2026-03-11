from __future__ import annotations

import unittest

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api import insights as insights_api


class _FakeAnalytics:
    async def emotion_stats(self, _db, user_id: int):
        return [{"label": "anxiety", "count": 3}] if user_id == 1 else []

    async def habit_stats(self, _db, user_id: int):
        return [{"habit": "procrastinating", "count": 2}] if user_id == 1 else []

    async def time_patterns(self, _db, user_id: int):
        return [{"hour_of_day": 9, "top_emotion": "anxiety", "message_count": 2}] if user_id == 1 else []

    async def overview_metrics(self, _db, user_id: int):
        if user_id != 1:
            return {"total_messages": 0, "active_days": 0, "dominant_emotion": None, "dominant_habit": None}
        return {"total_messages": 5, "active_days": 3, "dominant_emotion": "anxiety", "dominant_habit": "procrastinating"}

    async def daily_emotion_trends(self, _db, user_id: int):
        if user_id != 1:
            return []
        return [{"date": "2026-03-10", "total": 2, "emotions": [{"label": "anxiety", "count": 2}]}]

    async def daily_habit_trends(self, _db, user_id: int):
        if user_id != 1:
            return []
        return [{"date": "2026-03-10", "total": 1, "habits": [{"habit": "procrastinating", "count": 1}]}]

    async def habit_emotion_links(self, _db, user_id: int, min_count: int = 1, top_n: int = 50):
        if user_id != 1:
            return []
        rows = [{"habit": "procrastinating", "emotion": "anxiety", "co_occurrence": 2, "habit_total": 3, "link_strength": 0.6667}]
        return rows[:top_n] if min_count <= 2 else []


class InsightsApiTests(unittest.TestCase):
    def setUp(self):
        self._old_analytics = insights_api.analytics
        insights_api.analytics = _FakeAnalytics()

        self.app = FastAPI()

        async def _fake_db():
            yield object()

        self.app.dependency_overrides[insights_api.get_db_session] = _fake_db
        self.app.include_router(insights_api.router)
        self.client = TestClient(self.app)

    def tearDown(self):
        insights_api.analytics = self._old_analytics

    def test_existing_endpoint_shape_preserved(self):
        response = self.client.get("/insights/emotions", params={"user_id": 1})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), [{"label": "anxiety", "count": 3}])

    def test_new_overview_endpoint(self):
        response = self.client.get("/insights/overview", params={"user_id": 1})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                "total_messages": 5,
                "active_days": 3,
                "dominant_emotion": "anxiety",
                "dominant_habit": "procrastinating",
            },
        )

    def test_new_association_endpoint(self):
        response = self.client.get(
            "/insights/associations/habit-emotion",
            params={"user_id": 1, "min_count": 1, "top_n": 10},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            [
                {
                    "habit": "procrastinating",
                    "emotion": "anxiety",
                    "co_occurrence": 2,
                    "habit_total": 3,
                    "link_strength": 0.6667,
                }
            ],
        )


if __name__ == "__main__":
    unittest.main()
