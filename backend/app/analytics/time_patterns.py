from __future__ import annotations

from collections import Counter, defaultdict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.conversation import Conversation
from app.models.message import Message, MessageRole
from app.models.message_analysis import MessageAnalysis
from app.models.user_habit import UserHabit
from app.models.user_habit_check import UserHabitCheck


class TimePatternAnalytics:
    """Temporal analytics for emotions and habits."""

    @staticmethod
    def _normalize_label(value: str | None) -> str:
        if not value:
            return ""
        return value.strip().lower()

    async def emotion_stats(self, db: AsyncSession, user_id: int) -> list[dict]:
        query = (
            select(MessageAnalysis.emotions_json)
            .join(Message, Message.id == MessageAnalysis.message_id)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Conversation.user_id == user_id)
        )
        rows = (await db.execute(query)).scalars().all()

        counts: Counter[str] = Counter()
        for row in rows:
            for emotion in row.get("emotions", []):
                counts[emotion["label"]] += 1

        return [{"label": k, "count": v} for k, v in counts.most_common()]

    async def habit_stats(self, db: AsyncSession, user_id: int) -> list[dict]:
        query = (
            select(MessageAnalysis.habits_json)
            .join(Message, Message.id == MessageAnalysis.message_id)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Conversation.user_id == user_id)
        )
        rows = (await db.execute(query)).scalars().all()

        counts: Counter[str] = Counter()
        for row in rows:
            for habit in row.get("habits", []):
                label = self._normalize_label(habit.get("habit"))
                if label:
                    counts[label] += 1

        completed_habit_names = (
            await db.execute(
                select(UserHabit.name)
                .join(UserHabitCheck, UserHabitCheck.habit_id == UserHabit.id)
                .where(UserHabit.user_id == user_id, UserHabitCheck.is_completed.is_(True))
            )
        ).scalars().all()
        for habit_name in completed_habit_names:
            label = self._normalize_label(habit_name)
            if label:
                counts[label] += 1

        return [{"habit": k, "count": v} for k, v in counts.most_common()]

    async def time_patterns(self, db: AsyncSession, user_id: int) -> list[dict]:
        query = (
            select(Message.timestamp, MessageAnalysis.emotions_json)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .join(MessageAnalysis, MessageAnalysis.message_id == Message.id)
            .where(Message.role == MessageRole.USER)
            .where(Conversation.user_id == user_id)
        )

        rows = (await db.execute(query)).all()
        bucket: dict[int, Counter[str]] = defaultdict(Counter)
        for timestamp, emotions_json in rows:
            hour = timestamp.hour
            for emotion in emotions_json.get("emotions", []):
                bucket[hour][emotion["label"]] += 1

        result: list[dict] = []
        for hour, counter in sorted(bucket.items(), key=lambda pair: pair[0]):
            label, count = counter.most_common(1)[0]
            result.append({"hour_of_day": hour, "top_emotion": label, "message_count": count})
        return result

    async def overview_metrics(self, db: AsyncSession, user_id: int) -> dict:
        query = (
            select(Message.timestamp, MessageAnalysis.emotions_json, MessageAnalysis.habits_json)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .join(MessageAnalysis, MessageAnalysis.message_id == Message.id)
            .where(Message.role == MessageRole.USER)
            .where(Conversation.user_id == user_id)
        )

        rows = (await db.execute(query)).all()

        total_messages = len(rows)
        active_days = len({timestamp.date() for timestamp, _, _ in rows})

        emotion_counts: Counter[str] = Counter()
        habit_counts: Counter[str] = Counter()
        for _, emotions_json, habits_json in rows:
            for emotion in emotions_json.get("emotions", []):
                label = self._normalize_label(emotion.get("label"))
                if label:
                    emotion_counts[label] += 1
            for habit in habits_json.get("habits", []):
                label = self._normalize_label(habit.get("habit"))
                if label:
                    habit_counts[label] += 1

        completed_habit_names = (
            await db.execute(
                select(UserHabit.name)
                .join(UserHabitCheck, UserHabitCheck.habit_id == UserHabit.id)
                .where(UserHabit.user_id == user_id, UserHabitCheck.is_completed.is_(True))
            )
        ).scalars().all()
        for habit_name in completed_habit_names:
            label = self._normalize_label(habit_name)
            if label:
                habit_counts[label] += 1

        dominant_emotion = emotion_counts.most_common(1)[0][0] if emotion_counts else None
        dominant_habit = habit_counts.most_common(1)[0][0] if habit_counts else None

        return {
            "total_messages": total_messages,
            "active_days": active_days,
            "dominant_emotion": dominant_emotion,
            "dominant_habit": dominant_habit,
        }

    async def daily_emotion_trends(self, db: AsyncSession, user_id: int) -> list[dict]:
        query = (
            select(Message.timestamp, MessageAnalysis.emotions_json)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .join(MessageAnalysis, MessageAnalysis.message_id == Message.id)
            .where(Message.role == MessageRole.USER)
            .where(Conversation.user_id == user_id)
        )

        rows = (await db.execute(query)).all()
        day_bucket: dict[str, Counter[str]] = defaultdict(Counter)

        for timestamp, emotions_json in rows:
            day_key = timestamp.date().isoformat()
            for emotion in emotions_json.get("emotions", []):
                label = self._normalize_label(emotion.get("label"))
                if label:
                    day_bucket[day_key][label] += 1

        result: list[dict] = []
        for day_key in sorted(day_bucket.keys()):
            counter = day_bucket[day_key]
            points = [{"label": label, "count": count} for label, count in counter.most_common()]
            result.append({"date": day_key, "total": sum(counter.values()), "emotions": points})

        return result

    async def daily_habit_trends(self, db: AsyncSession, user_id: int) -> list[dict]:
        query = (
            select(Message.timestamp, MessageAnalysis.habits_json)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .join(MessageAnalysis, MessageAnalysis.message_id == Message.id)
            .where(Message.role == MessageRole.USER)
            .where(Conversation.user_id == user_id)
        )

        rows = (await db.execute(query)).all()
        day_bucket: dict[str, Counter[str]] = defaultdict(Counter)

        for timestamp, habits_json in rows:
            day_key = timestamp.date().isoformat()
            for habit in habits_json.get("habits", []):
                label = self._normalize_label(habit.get("habit"))
                if label:
                    day_bucket[day_key][label] += 1

        completed_rows = (
            await db.execute(
                select(UserHabitCheck.check_date, UserHabit.name)
                .join(UserHabit, UserHabit.id == UserHabitCheck.habit_id)
                .where(UserHabit.user_id == user_id, UserHabitCheck.is_completed.is_(True))
            )
        ).all()

        for check_date, habit_name in completed_rows:
            day_key = check_date.isoformat()
            label = self._normalize_label(habit_name)
            if label:
                day_bucket[day_key][label] += 1

        result: list[dict] = []
        for day_key in sorted(day_bucket.keys()):
            counter = day_bucket[day_key]
            points = [{"habit": habit, "count": count} for habit, count in counter.most_common()]
            result.append({"date": day_key, "total": sum(counter.values()), "habits": points})

        return result

    async def habit_emotion_links(
        self,
        db: AsyncSession,
        user_id: int,
        min_count: int = 1,
        top_n: int = 50,
    ) -> list[dict]:
        query = (
            select(MessageAnalysis.emotions_json, MessageAnalysis.habits_json)
            .join(Message, Message.id == MessageAnalysis.message_id)
            .join(Conversation, Conversation.id == Message.conversation_id)
            .where(Message.role == MessageRole.USER)
            .where(Conversation.user_id == user_id)
        )

        rows = (await db.execute(query)).all()

        pair_counts: Counter[tuple[str, str]] = Counter()
        habit_totals: Counter[str] = Counter()

        for emotions_json, habits_json in rows:
            emotions: set[str] = set()
            habits: set[str] = set()

            for item in emotions_json.get("emotions", []):
                label = self._normalize_label(item.get("label"))
                if label:
                    emotions.add(label)

            for item in habits_json.get("habits", []):
                label = self._normalize_label(item.get("habit"))
                if label:
                    habits.add(label)

            for habit in habits:
                habit_totals[habit] += 1

            for habit in habits:
                for emotion in emotions:
                    pair_counts[(habit, emotion)] += 1

        results: list[dict] = []
        for (habit, emotion), co_occurrence in pair_counts.items():
            if co_occurrence < min_count:
                continue
            habit_total = habit_totals[habit]
            link_strength = (co_occurrence / habit_total) if habit_total else 0.0
            results.append(
                {
                    "habit": habit,
                    "emotion": emotion,
                    "co_occurrence": co_occurrence,
                    "habit_total": habit_total,
                    "link_strength": round(link_strength, 4),
                }
            )

        results.sort(key=lambda item: (-item["co_occurrence"], -item["link_strength"], item["habit"], item["emotion"]))
        return results[:top_n]
