from __future__ import annotations

from datetime import date, datetime
from pathlib import Path
from types import SimpleNamespace
import sys
import unittest

from fastapi import FastAPI
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.api import recommendations as recommendations_api


def _fake_item(item_id: int, kind: str = "habit"):
    return SimpleNamespace(
        id=item_id,
        batch_id=11,
        position=1,
        category="balance",
        kind=kind,
        title="Daily anchor",
        rationale="Keep the step small and repeatable.",
        action_payload_json={"habit_name": "Daily anchor", "timer_seconds": 300},
        estimated_duration_minutes=5,
        follow_up_text="Try it before lunch.",
        status="pending",
        completed_at=None,
        created_at=datetime(2026, 3, 13, 9, 0, 0),
    )


class _FakeRecommendationService:
    async def get_or_create_today_batch(self, _db, *, user_id: int, category: str = "balance"):
        return SimpleNamespace(
            id=11,
            user_id=user_id,
            category=category,
            batch_date=date(2026, 3, 13),
            is_active=True,
            created_at=datetime(2026, 3, 13, 9, 0, 0),
            items=[_fake_item(31), _fake_item(32, kind="timed_action")],
        )

    async def generate_batch(self, _db, *, user_id: int, category: str):
        return await self.get_or_create_today_batch(_db, user_id=user_id, category=category)

    async def get_history(self, _db, *, user_id: int, limit: int = 10):
        batch = await self.get_or_create_today_batch(_db, user_id=user_id, category="balance")
        return [batch][:limit]

    async def select_item(self, _db, *, user_id: int, item_id: int):
        item = _fake_item(item_id)
        item.status = "selected"
        return item

    async def complete_item(self, _db, *, user_id: int, item_id: int):
        item = _fake_item(item_id, kind="instant_action")
        item.status = "completed"
        item.completed_at = datetime(2026, 3, 13, 10, 0, 0)
        return item

    async def log_item_interaction(self, _db, *, user_id: int, item_id: int, event_type: str, payload: dict):
        return None

    async def adopt_habit(self, _db, *, user_id: int, item_id: int):
        return SimpleNamespace(
            id=4,
            user_id=user_id,
            source_recommendation_item_id=item_id,
            name="Daily anchor",
            category="balance",
            cue_text="Pause before lunch.",
            reason_text="Keep the step small and repeatable.",
            is_active=True,
            created_at=datetime(2026, 3, 13, 9, 15, 0),
            archived_at=None,
        )

    async def get_daily_checklist(self, _db, *, user_id: int, for_date: date | None = None):
        habit = await self.adopt_habit(_db, user_id=user_id, item_id=31)
        check = SimpleNamespace(is_completed=True, completed_at=datetime(2026, 3, 13, 9, 45, 0), check_date=date(2026, 3, 13))
        return [(habit, check)]

    async def set_habit_check(self, _db, *, user_id: int, habit_id: int, for_date: date | None, completed: bool):
        return SimpleNamespace(is_completed=completed, completed_at=datetime(2026, 3, 13, 9, 45, 0), check_date=date(2026, 3, 13))

    async def delete_habit(self, _db, *, user_id: int, habit_id: int):
        if user_id != 3 or habit_id != 4:
            raise ValueError("Habit not found for this user")
        return None

    def _today(self):
        return date(2026, 3, 13)


class RecommendationsApiTests(unittest.TestCase):
    def setUp(self):
        self.old_service = recommendations_api.recommendation_service
        recommendations_api.recommendation_service = _FakeRecommendationService()

        self.app = FastAPI()

        async def _fake_db():
            yield object()

        self.app.dependency_overrides[recommendations_api.get_db_session] = _fake_db
        self.app.include_router(recommendations_api.router)
        self.client = TestClient(self.app)

    def tearDown(self):
        recommendations_api.recommendation_service = self.old_service

    def test_today_endpoint_returns_batch_shape(self):
        response = self.client.get("/recommendations/today", params={"user_id": 3, "category": "calm"})
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["user_id"], 3)
        self.assertEqual(data["category"], "calm")
        self.assertEqual(len(data["items"]), 2)

    def test_habit_check_endpoint_returns_updated_item(self):
        response = self.client.put(
            "/recommendations/habits/4/check",
            json={"user_id": 3, "completed": True},
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["is_completed"])
        self.assertEqual(data["habit"]["id"], 4)

    def test_delete_habit_endpoint_returns_no_content(self):
        response = self.client.delete("/recommendations/habits/4", params={"user_id": 3})
        self.assertEqual(response.status_code, 204)
        self.assertEqual(response.content, b"")

    def test_delete_habit_endpoint_returns_not_found_for_other_user(self):
        response = self.client.delete("/recommendations/habits/4", params={"user_id": 7})
        self.assertEqual(response.status_code, 404)
        self.assertEqual(response.json()["detail"], "Habit not found for this user")


if __name__ == "__main__":
    unittest.main()