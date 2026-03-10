from __future__ import annotations

from collections import Counter, defaultdict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.message import Message, MessageRole
from app.models.message_analysis import MessageAnalysis


class TimePatternAnalytics:
    """Temporal analytics for emotions and habits."""

    async def emotion_stats(self, db: AsyncSession, conversation_id: int | None = None) -> list[dict]:
        query = select(MessageAnalysis.emotions_json)
        if conversation_id is not None:
            query = query.join(Message, Message.id == MessageAnalysis.message_id).where(Message.conversation_id == conversation_id)
        rows = (await db.execute(query)).scalars().all()

        counts: Counter[str] = Counter()
        for row in rows:
            for emotion in row.get("emotions", []):
                counts[emotion["label"]] += 1

        return [{"label": k, "count": v} for k, v in counts.most_common()]

    async def habit_stats(self, db: AsyncSession, conversation_id: int | None = None) -> list[dict]:
        query = select(MessageAnalysis.habits_json)
        if conversation_id is not None:
            query = query.join(Message, Message.id == MessageAnalysis.message_id).where(Message.conversation_id == conversation_id)
        rows = (await db.execute(query)).scalars().all()

        counts: Counter[str] = Counter()
        for row in rows:
            for habit in row.get("habits", []):
                counts[habit["habit"]] += 1

        return [{"habit": k, "count": v} for k, v in counts.most_common()]

    async def time_patterns(self, db: AsyncSession, conversation_id: int | None = None) -> list[dict]:
        query = (
            select(Message.timestamp, MessageAnalysis.emotions_json)
            .join(MessageAnalysis, MessageAnalysis.message_id == Message.id)
            .where(Message.role == MessageRole.USER)
        )
        if conversation_id is not None:
            query = query.where(Message.conversation_id == conversation_id)

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
