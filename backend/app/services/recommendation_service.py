from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime
import json
from typing import Any

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.analytics.time_patterns import TimePatternAnalytics
from app.config import get_settings
from app.models.recommendation_batch import RecommendationBatch
from app.models.recommendation_interaction import RecommendationInteraction
from app.models.recommendation_item import RecommendationItem
from app.models.user import User
from app.models.user_chat_memory import UserChatMemory
from app.models.user_habit import UserHabit
from app.models.user_habit_check import UserHabitCheck
from app.services.llm_service import LLMService


@dataclass
class RecommendationContext:
    emotion_stats: list[dict[str, Any]]
    habit_stats: list[dict[str, Any]]
    time_patterns: list[dict[str, Any]]
    recent_memories: list[str]
    active_habits: list[dict[str, Any]]
    recent_interactions: list[dict[str, Any]]


class RecommendationService:
    def __init__(
        self,
        llm_service: LLMService | None = None,
        analytics_service: TimePatternAnalytics | None = None,
        *,
        now_provider: callable | None = None,
    ) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.analytics = analytics_service or TimePatternAnalytics()
        self.now_provider = now_provider or datetime.utcnow

    async def get_or_create_today_batch(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        category: str = "balance",
    ) -> RecommendationBatch:
        await self._ensure_user(db, user_id=user_id)
        batch = await self._get_active_batch(db, user_id=user_id, batch_date=self._today(), category=category)
        if batch is not None:
            return batch
        return await self.generate_batch(db, user_id=user_id, category=category)

    async def generate_batch(self, db: AsyncSession, *, user_id: int, category: str) -> RecommendationBatch:
        await self._ensure_user(db, user_id=user_id)
        batch_date = self._today()
        context = await self._build_context(db, user_id=user_id)
        items = await self._generate_items(category=category, context=context)

        active_batches = (
            await db.execute(
                select(RecommendationBatch)
                .where(
                    RecommendationBatch.user_id == user_id,
                    RecommendationBatch.batch_date == batch_date,
                    RecommendationBatch.is_active.is_(True),
                )
            )
        ).scalars().all()
        for existing in active_batches:
            existing.is_active = False

        batch = RecommendationBatch(
            user_id=user_id,
            category=category,
            batch_date=batch_date,
            is_active=True,
            context_summary_json={
                "emotion_stats": context.emotion_stats,
                "habit_stats": context.habit_stats,
                "time_patterns": context.time_patterns,
                "recent_memories": context.recent_memories,
                "active_habits": context.active_habits,
                "recent_interactions": context.recent_interactions,
            },
        )
        db.add(batch)
        await db.flush()

        for position, item in enumerate(items, start=1):
            db.add(
                RecommendationItem(
                    batch_id=batch.id,
                    position=position,
                    category=category,
                    kind=item["kind"],
                    title=item["title"],
                    rationale=item["rationale"],
                    action_payload_json=item.get("action_payload", {}),
                    estimated_duration_minutes=item.get("estimated_duration_minutes"),
                    follow_up_text=item.get("follow_up_text"),
                )
            )

        await db.flush()
        await self._log_event(
            db,
            user_id=user_id,
            batch_id=batch.id,
            item_id=None,
            event_type="batch_generated",
            payload={"category": category},
        )
        await db.commit()
        return await self._load_batch(db, batch.id, user_id=user_id)

    async def get_history(self, db: AsyncSession, *, user_id: int, limit: int = 10) -> list[RecommendationBatch]:
        rows = (
            await db.execute(
                select(RecommendationBatch)
                .where(RecommendationBatch.user_id == user_id)
                .options(selectinload(RecommendationBatch.items))
                .order_by(RecommendationBatch.batch_date.desc(), RecommendationBatch.created_at.desc(), RecommendationBatch.id.desc())
                .limit(limit)
            )
        ).scalars().all()
        return list(rows)

    async def select_item(self, db: AsyncSession, *, user_id: int, item_id: int) -> RecommendationItem:
        item = await self._get_item_owned_by_user(db, user_id=user_id, item_id=item_id)
        if item.status == "pending":
            item.status = "selected"
        await self._log_event(
            db,
            user_id=user_id,
            batch_id=item.batch_id,
            item_id=item.id,
            event_type="selected",
            payload={"kind": item.kind},
        )
        await db.commit()
        await db.refresh(item)
        return item

    async def complete_item(self, db: AsyncSession, *, user_id: int, item_id: int) -> RecommendationItem:
        item = await self._get_item_owned_by_user(db, user_id=user_id, item_id=item_id)
        item.status = "completed"
        item.completed_at = self.now_provider()
        await self._log_event(
            db,
            user_id=user_id,
            batch_id=item.batch_id,
            item_id=item.id,
            event_type="completed",
            payload={"kind": item.kind},
        )
        await db.commit()
        await db.refresh(item)
        return item

    async def log_item_interaction(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        item_id: int,
        event_type: str,
        payload: dict[str, Any],
    ) -> None:
        item = await self._get_item_owned_by_user(db, user_id=user_id, item_id=item_id)
        await self._log_event(
            db,
            user_id=user_id,
            batch_id=item.batch_id,
            item_id=item.id,
            event_type=event_type,
            payload=payload,
        )
        await db.commit()

    async def adopt_habit(self, db: AsyncSession, *, user_id: int, item_id: int) -> UserHabit:
        item = await self._get_item_owned_by_user(db, user_id=user_id, item_id=item_id)
        habit_name = str(item.action_payload_json.get("habit_name") or item.title).strip()
        existing = (
            await db.execute(
                select(UserHabit).where(
                    UserHabit.user_id == user_id,
                    UserHabit.name == habit_name,
                    UserHabit.is_active.is_(True),
                )
            )
        ).scalar_one_or_none()
        if existing is not None:
            return existing

        habit = UserHabit(
            user_id=user_id,
            source_recommendation_item_id=item.id,
            name=habit_name,
            category=item.category,
            cue_text=item.action_payload_json.get("cue_text"),
            reason_text=item.rationale,
            is_active=True,
        )
        db.add(habit)
        await db.flush()
        await self._log_event(
            db,
            user_id=user_id,
            batch_id=item.batch_id,
            item_id=item.id,
            event_type="habit_adopted",
            payload={"habit_id": habit.id, "habit_name": habit.name},
        )
        if item.status == "pending":
            item.status = "selected"
        await db.commit()
        await db.refresh(habit)
        return habit

    async def create_habit(self, db: AsyncSession, *, user_id: int, name: str) -> UserHabit:
        name = name.strip()
        existing = (
            await db.execute(
                select(UserHabit).where(
                    UserHabit.user_id == user_id,
                    UserHabit.name == name,
                    UserHabit.is_active.is_(True),
                )
            )
        ).scalar_one_or_none()
        if existing is not None:
            return existing
        habit = UserHabit(
            user_id=user_id,
            name=name,
            category="general",
            is_active=True,
        )
        db.add(habit)
        await db.commit()
        await db.refresh(habit)
        return habit

    async def get_daily_checklist(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        for_date: date | None = None,
    ) -> list[tuple[UserHabit, UserHabitCheck | None]]:
        target_date = for_date or self._today()
        habits = (
            await db.execute(
                select(UserHabit)
                .where(UserHabit.user_id == user_id, UserHabit.is_active.is_(True))
                .order_by(UserHabit.created_at.desc(), UserHabit.id.desc())
            )
        ).scalars().all()

        habit_ids = [habit.id for habit in habits]
        checks_by_habit_id: dict[int, UserHabitCheck] = {}
        if habit_ids:
            checks = (
                await db.execute(
                    select(UserHabitCheck).where(
                        UserHabitCheck.habit_id.in_(habit_ids),
                        UserHabitCheck.check_date == target_date,
                    )
                )
            ).scalars().all()
            checks_by_habit_id = {entry.habit_id: entry for entry in checks}

        result: list[tuple[UserHabit, UserHabitCheck | None]] = []
        for habit in habits:
            result.append((habit, checks_by_habit_id.get(habit.id)))
        return result

    async def delete_habit(self, db: AsyncSession, *, user_id: int, habit_id: int) -> None:
        habit = await self._get_habit_owned_by_user(db, user_id=user_id, habit_id=habit_id)
        await db.delete(habit)
        await db.commit()

    async def set_habit_check(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        habit_id: int,
        for_date: date | None,
        completed: bool,
    ) -> UserHabitCheck:
        target_date = for_date or self._today()
        habit = (
            await db.execute(select(UserHabit).where(UserHabit.id == habit_id, UserHabit.user_id == user_id))
        ).scalar_one_or_none()
        if habit is None:
            raise ValueError("Habit not found for this user")

        check = (
            await db.execute(
                select(UserHabitCheck).where(
                    UserHabitCheck.habit_id == habit_id,
                    UserHabitCheck.check_date == target_date,
                )
            )
        ).scalar_one_or_none()

        if check is None:
            check = UserHabitCheck(habit_id=habit_id, check_date=target_date)
            db.add(check)

        check.is_completed = completed
        check.completed_at = self.now_provider() if completed else None

        await self._log_event(
            db,
            user_id=user_id,
            batch_id=None,
            item_id=habit.source_recommendation_item_id,
            event_type="habit_checked" if completed else "habit_unchecked",
            payload={"habit_id": habit.id, "date": target_date.isoformat()},
        )
        await db.commit()
        await db.refresh(check)
        return check

    async def _ensure_user(self, db: AsyncSession, *, user_id: int) -> None:
        user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
        if user is None:
            db.add(User(id=user_id))
            await db.flush()

    async def _build_context(self, db: AsyncSession, *, user_id: int) -> RecommendationContext:
        emotion_stats = await self.analytics.emotion_stats(db, user_id=user_id)
        habit_stats = await self.analytics.habit_stats(db, user_id=user_id)
        time_patterns = await self.analytics.time_patterns(db, user_id=user_id)
        recent_memories = (
            await db.execute(
                select(UserChatMemory.summary)
                .where(UserChatMemory.user_id == user_id)
                .order_by(UserChatMemory.created_at.desc(), UserChatMemory.id.desc())
                .limit(4)
            )
        ).scalars().all()
        active_habits = (
            await db.execute(
                select(UserHabit)
                .where(UserHabit.user_id == user_id, UserHabit.is_active.is_(True))
                .order_by(UserHabit.created_at.desc(), UserHabit.id.desc())
                .limit(6)
            )
        ).scalars().all()
        recent_interactions = (
            await db.execute(
                select(RecommendationInteraction)
                .where(RecommendationInteraction.user_id == user_id)
                .order_by(RecommendationInteraction.created_at.desc(), RecommendationInteraction.id.desc())
                .limit(8)
            )
        ).scalars().all()

        return RecommendationContext(
            emotion_stats=emotion_stats[:4],
            habit_stats=habit_stats[:4],
            time_patterns=time_patterns[:4],
            recent_memories=list(recent_memories),
            active_habits=[
                {"name": habit.name, "category": habit.category, "cue_text": habit.cue_text, "reason_text": habit.reason_text}
                for habit in active_habits
            ],
            recent_interactions=[
                {"event_type": row.event_type, "payload": row.event_payload_json, "created_at": row.created_at.isoformat()}
                for row in recent_interactions
            ],
        )

    async def _generate_items(self, *, category: str, context: RecommendationContext) -> list[dict[str, Any]]:
        if not self.settings.groq_api_key:
            return self._fallback_items(category=category, context=context)

        system_prompt = (
            "You generate concise mental wellness recommendations. Return JSON only with this shape: "
            "{'items':[{'kind':'timed_action|habit|instant_action|reflection','title':str,'rationale':str,"
            "'action_payload':object,'estimated_duration_minutes':int|null,'follow_up_text':str|null}]}. "
            "Generate exactly 4 items. Keep titles under 60 characters. Make the recommendations actionable, calm, and specific."
        )
        user_prompt = (
            f"Selected category: {category}\n"
            "Use this user context:\n"
            f"{json.dumps({
                'emotion_stats': context.emotion_stats,
                'habit_stats': context.habit_stats,
                'time_patterns': context.time_patterns,
                'recent_memories': context.recent_memories,
                'active_habits': context.active_habits,
                'recent_interactions': context.recent_interactions,
            }, default=str)}"
        )
        payload = await self.llm.generate_structured_json(system_prompt, user_prompt, max_tokens=700)
        return self._normalize_items(payload.get("items"), category=category, context=context)

    def _normalize_items(self, raw_items: Any, *, category: str, context: RecommendationContext) -> list[dict[str, Any]]:
        if not isinstance(raw_items, list):
            return self._fallback_items(category=category, context=context)

        allowed_kinds = {"timed_action", "habit", "instant_action", "reflection"}
        normalized: list[dict[str, Any]] = []
        for raw in raw_items[:4]:
            if not isinstance(raw, dict):
                continue
            kind = str(raw.get("kind") or "instant_action").strip().lower()
            if kind not in allowed_kinds:
                kind = "instant_action"
            title = str(raw.get("title") or "Try a small reset").strip()[:255]
            rationale = str(raw.get("rationale") or "A smaller step is easier to sustain when your energy shifts.").strip()
            action_payload = raw.get("action_payload") if isinstance(raw.get("action_payload"), dict) else {}
            estimated = raw.get("estimated_duration_minutes")
            estimated_minutes = estimated if isinstance(estimated, int) and estimated > 0 else None
            follow_up_text = raw.get("follow_up_text")
            normalized.append(
                {
                    "kind": kind,
                    "title": title,
                    "rationale": rationale,
                    "action_payload": action_payload,
                    "estimated_duration_minutes": estimated_minutes,
                    "follow_up_text": str(follow_up_text).strip() if isinstance(follow_up_text, str) and follow_up_text.strip() else None,
                }
            )

        if len(normalized) < 2:
            return self._fallback_items(category=category, context=context)

        for item in normalized:
            if item["kind"] == "habit":
                item["action_payload"].setdefault("habit_name", item["title"])
            if item["kind"] == "timed_action":
                item["action_payload"].setdefault("timer_seconds", (item["estimated_duration_minutes"] or 8) * 60)

        return normalized

    def _fallback_items(self, *, category: str, context: RecommendationContext) -> list[dict[str, Any]]:
        dominant_emotion = context.emotion_stats[0]["label"] if context.emotion_stats else "stress"
        top_habit = context.habit_stats[0]["habit"] if context.habit_stats else "scrolling"
        top_hour = context.time_patterns[0]["hour_of_day"] if context.time_patterns else 9
        category_openers = {
            "balance": "steady your day",
            "calm": "settle your nervous system",
            "energy": "rebuild momentum",
            "focus": "protect your attention",
            "reflection": "notice what is underneath the pattern",
        }
        opener = category_openers.get(category, "take one steady next step")
        return [
            {
                "kind": "timed_action",
                "title": f"8-minute {category} reset",
                "rationale": f"Your recent pattern points to {dominant_emotion}. A short timed reset can help {opener} without asking for too much energy.",
                "action_payload": {
                    "timer_seconds": 480,
                    "prompt": f"Step away from {top_habit} and do one grounding action around {top_hour}:00.",
                },
                "estimated_duration_minutes": 8,
                "follow_up_text": "Notice whether your body feels a little less rushed afterward.",
            },
            {
                "kind": "habit",
                "title": f"Daily {category} anchor",
                "rationale": f"A repeatable anchor is more useful than a perfect plan when {dominant_emotion} keeps returning.",
                "action_payload": {
                    "habit_name": f"{category.title()} anchor",
                    "cue_text": f"When the clock reaches about {top_hour}:00, pause for one intentional breath and a small reset.",
                },
                "estimated_duration_minutes": 5,
                "follow_up_text": "Adopt this as a habit if you want it to appear in your daily checklist.",
            },
            {
                "kind": "instant_action",
                "title": f"Reduce one friction point in {top_habit}",
                "rationale": f"Your recent habits suggest {top_habit} may be draining attention. Shrinking one friction point is easier than changing everything.",
                "action_payload": {
                    "step": f"Choose one small boundary around {top_habit} for the next two hours.",
                },
                "estimated_duration_minutes": 3,
                "follow_up_text": "Mark this complete once you have chosen the boundary.",
            },
            {
                "kind": "reflection",
                "title": "Bring this pattern into chat",
                "rationale": "A short reflection can turn the pattern into something more precise and easier to work with.",
                "action_payload": {
                    "prompt": f"Lately I notice {dominant_emotion} shows up when {top_habit} gets stronger. Help me unpack that.",
                },
                "estimated_duration_minutes": 10,
                "follow_up_text": "Open chat and use the suggested prompt if you want to explore it further.",
            },
        ]

    async def _get_active_batch(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        batch_date: date,
        category: str | None = None,
    ) -> RecommendationBatch | None:
        filters = [
            RecommendationBatch.user_id == user_id,
            RecommendationBatch.batch_date == batch_date,
            RecommendationBatch.is_active.is_(True),
        ]
        if category is not None:
            filters.append(RecommendationBatch.category == category)
        batch = (
            await db.execute(
                select(RecommendationBatch)
                .where(and_(*filters))
                .options(selectinload(RecommendationBatch.items))
                .order_by(RecommendationBatch.created_at.desc(), RecommendationBatch.id.desc())
            )
        ).scalars().first()
        return batch

    async def _load_batch(self, db: AsyncSession, batch_id: int, *, user_id: int) -> RecommendationBatch:
        batch = (
            await db.execute(
                select(RecommendationBatch)
                .where(RecommendationBatch.id == batch_id, RecommendationBatch.user_id == user_id)
                .options(selectinload(RecommendationBatch.items))
            )
        ).scalar_one()
        return batch

    async def _get_item_owned_by_user(self, db: AsyncSession, *, user_id: int, item_id: int) -> RecommendationItem:
        item = (
            await db.execute(
                select(RecommendationItem)
                .join(RecommendationBatch, RecommendationBatch.id == RecommendationItem.batch_id)
                .where(RecommendationItem.id == item_id, RecommendationBatch.user_id == user_id)
            )
        ).scalar_one_or_none()
        if item is None:
            raise ValueError("Recommendation item not found for this user")
        return item

    async def _get_habit_owned_by_user(self, db: AsyncSession, *, user_id: int, habit_id: int) -> UserHabit:
        habit = (
            await db.execute(
                select(UserHabit).where(UserHabit.id == habit_id, UserHabit.user_id == user_id)
            )
        ).scalar_one_or_none()
        if habit is None:
            raise ValueError("Habit not found for this user")
        return habit

    async def _log_event(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        batch_id: int | None,
        item_id: int | None,
        event_type: str,
        payload: dict[str, Any],
    ) -> None:
        db.add(
            RecommendationInteraction(
                user_id=user_id,
                batch_id=batch_id,
                item_id=item_id,
                event_type=event_type,
                event_payload_json=payload,
            )
        )
        await db.flush()

    def _today(self) -> date:
        return self.now_provider().date()