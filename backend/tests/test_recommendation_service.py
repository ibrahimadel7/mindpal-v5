from __future__ import annotations

from datetime import datetime
from pathlib import Path
import sys
import unittest

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database.base import Base
from app.models.recommendation_batch import RecommendationBatch
from app.models.recommendation_interaction import RecommendationInteraction
from app.models.recommendation_item import RecommendationItem
from app.models.user_habit import UserHabit
from app.models.user_habit_check import UserHabitCheck
from app.services.recommendation_service import RecommendationService


class _FakeVectorService:
    async def search_knowledge_entries(
        self,
        query: str,
        top_k: int,
        *,
        tags: list[str] | None = None,
        include_crisis: bool = False,
    ) -> list[dict]:
        return [
            {
                "id": "kb_who_0001",
                "content": "Take a short breathing pause to reduce stress.",
                "metadata": {
                    "title": "WHO Breathing Reset",
                    "category": "coping",
                    "tags": "stress,breathing",
                    "is_crisis": False,
                },
                "distance": 0.1,
                "tag_overlap": 1,
            }
        ]


class RecommendationServiceTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        self.session_factory = sessionmaker(self.engine, class_=AsyncSession, expire_on_commit=False)
        self.fixed_now = datetime(2026, 3, 13, 9, 30, 0)
        self.service = RecommendationService(now_provider=lambda: self.fixed_now)
        self.service.vector = _FakeVectorService()
        self.original_groq_key = self.service.settings.groq_api_key
        self.service.settings.groq_api_key = ""

    async def asyncTearDown(self) -> None:
        self.service.settings.groq_api_key = self.original_groq_key
        await self.engine.dispose()

    async def test_generate_batch_replaces_active_batch_but_keeps_history(self) -> None:
        async with self.session_factory() as session:
            first = await self.service.generate_batch(session, user_id=1, category="balance")
            second = await self.service.generate_batch(session, user_id=1, category="focus")

            batches = (
                await session.execute(
                    select(RecommendationBatch)
                    .where(RecommendationBatch.user_id == 1)
                    .order_by(RecommendationBatch.id.asc())
                )
            ).scalars().all()

            self.assertEqual(len(batches), 2)
            self.assertFalse(batches[0].is_active)
            self.assertTrue(batches[1].is_active)
            self.assertEqual(first.id, batches[0].id)
            self.assertEqual(second.id, batches[1].id)
            self.assertEqual(len(first.items), 4)
            self.assertEqual(len(second.items), 4)
            self.assertIn("who_entries", second.context_summary_json)
            self.assertEqual(len(second.context_summary_json["who_entries"]), 1)

    async def test_adopt_habit_and_complete_daily_checklist(self) -> None:
        async with self.session_factory() as session:
            batch = await self.service.generate_batch(session, user_id=8, category="calm")
            habit_item = next(item for item in batch.items if item.kind == "habit")

            habit = await self.service.adopt_habit(session, user_id=8, item_id=habit_item.id)
            self.assertIsInstance(habit, UserHabit)
            self.assertEqual(habit.source_recommendation_item_id, habit_item.id)

            checklist_before = await self.service.get_daily_checklist(session, user_id=8, for_date=self.fixed_now.date())
            self.assertEqual(len(checklist_before), 1)
            self.assertFalse(checklist_before[0][1] is not None and checklist_before[0][1].is_completed)

            check = await self.service.set_habit_check(
                session,
                user_id=8,
                habit_id=habit.id,
                for_date=self.fixed_now.date(),
                completed=True,
            )
            self.assertTrue(check.is_completed)

            checklist_after = await self.service.get_daily_checklist(session, user_id=8, for_date=self.fixed_now.date())
            self.assertEqual(len(checklist_after), 1)
            self.assertIsNotNone(checklist_after[0][1])
            self.assertTrue(checklist_after[0][1].is_completed)

            interaction = (
                await session.execute(
                    select(RecommendationInteraction)
                    .where(
                        RecommendationInteraction.user_id == 8,
                        RecommendationInteraction.event_type == "habit_checked",
                    )
                    .order_by(RecommendationInteraction.id.desc())
                )
            ).scalars().first()
            self.assertIsNotNone(interaction)
            payload = interaction.event_payload_json
            self.assertEqual(payload["habit_id"], habit.id)
            self.assertEqual(payload["habit_name"], habit.name)
            self.assertEqual(payload["habit_category"], habit.category)
            self.assertEqual(payload["date"], self.fixed_now.date().isoformat())
            self.assertTrue(payload["completed"])

            stored_items = (
                await session.execute(select(RecommendationItem).where(RecommendationItem.batch_id == batch.id))
            ).scalars().all()
            self.assertEqual(len(stored_items), 4)

    async def test_delete_habit_removes_it_from_checklist_and_cascades_checks(self) -> None:
        async with self.session_factory() as session:
            batch = await self.service.generate_batch(session, user_id=11, category="focus")
            habit_item = next(item for item in batch.items if item.kind == "habit")

            habit = await self.service.adopt_habit(session, user_id=11, item_id=habit_item.id)
            await self.service.set_habit_check(
                session,
                user_id=11,
                habit_id=habit.id,
                for_date=self.fixed_now.date(),
                completed=True,
            )

            await self.service.delete_habit(session, user_id=11, habit_id=habit.id)

            checklist_after = await self.service.get_daily_checklist(session, user_id=11, for_date=self.fixed_now.date())
            self.assertEqual(checklist_after, [])

            stored_habit = (
                await session.execute(select(UserHabit).where(UserHabit.id == habit.id))
            ).scalar_one_or_none()
            self.assertIsNone(stored_habit)

            stored_checks = (
                await session.execute(select(UserHabitCheck).where(UserHabitCheck.habit_id == habit.id))
            ).scalars().all()
            self.assertEqual(stored_checks, [])

    async def test_delete_habit_raises_for_wrong_user(self) -> None:
        async with self.session_factory() as session:
            batch = await self.service.generate_batch(session, user_id=12, category="balance")
            habit_item = next(item for item in batch.items if item.kind == "habit")
            habit = await self.service.adopt_habit(session, user_id=12, item_id=habit_item.id)

            with self.assertRaisesRegex(ValueError, "Habit not found for this user"):
                await self.service.delete_habit(session, user_id=99, habit_id=habit.id)


if __name__ == "__main__":
    unittest.main()