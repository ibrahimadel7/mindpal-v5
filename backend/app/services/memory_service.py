from __future__ import annotations

import math
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.user import User
from app.models.user_memory import MemoryCategory, UserMemory, UserMemoryAuditLog, UserMemoryEntry
from app.services.llm_service import LLMService
from app.services.vector_service import VectorService


class MemoryService:
    def __init__(
        self,
        llm_service: LLMService | None = None,
        vector_service: VectorService | None = None,
    ) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.vector = vector_service or VectorService(self.llm)

    async def ensure_user_memory(self, db: AsyncSession, *, user_id: int) -> UserMemory:
        user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
        if user is None:
            user = User(id=user_id)
            db.add(user)
            await db.flush()

        profile = (await db.execute(select(UserMemory).where(UserMemory.user_id == user_id))).scalar_one_or_none()
        if profile is not None:
            return profile

        profile = UserMemory(user_id=user_id)
        db.add(profile)
        await db.flush()
        return profile

    async def add_memory_entry(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        content: str,
        category: str,
        source_conversation_id: int | None = None,
        relevance_score: float = 0.6,
        emotional_significance: float = 0.5,
        recurrence_count: int = 1,
    ) -> UserMemoryEntry:
        profile = await self.ensure_user_memory(db, user_id=user_id)
        normalized_content = self._clean_content(content)
        normalized_category = self._validate_category(category)

        embedding = (await self.llm.embed_texts([normalized_content]))[0]
        entry = UserMemoryEntry(
            user_memory_id=profile.id,
            user_id=user_id,
            category=normalized_category,
            content=normalized_content,
            embedding_json=embedding,
            relevance_score=self._clamp01(relevance_score),
            emotional_significance=self._clamp01(emotional_significance),
            recurrence_count=max(recurrence_count, 1),
            source_conversation_id=source_conversation_id,
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(entry)
        await db.flush()

        vector_id = f"memory-{entry.id}"
        entry.vector_id = vector_id
        await self.vector.upsert_memory_embedding(
            vector_id=vector_id,
            content=normalized_content,
            user_id=user_id,
            entry_id=entry.id,
            category=normalized_category,
            is_active=True,
            embedding=embedding,
        )

        profile.updated_at = datetime.utcnow()
        await self._refresh_profile_snapshot(db, profile=profile)
        await db.flush()
        return entry

    async def update_memory_entry(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        entry_id: int,
        updates: dict[str, Any],
    ) -> UserMemoryEntry:
        entry = (
            await db.execute(
                select(UserMemoryEntry).where(
                    UserMemoryEntry.id == entry_id,
                    UserMemoryEntry.user_id == user_id,
                )
            )
        ).scalar_one_or_none()
        if entry is None:
            raise ValueError("Memory entry not found")

        previous_content = entry.content
        previous_category = entry.category

        if "content" in updates and updates["content"]:
            entry.content = self._clean_content(str(updates["content"]))
        if "category" in updates and updates["category"]:
            entry.category = self._validate_category(str(updates["category"]))
        if "relevance_score" in updates and updates["relevance_score"] is not None:
            entry.relevance_score = self._clamp01(float(updates["relevance_score"]))
        if "emotional_significance" in updates and updates["emotional_significance"] is not None:
            entry.emotional_significance = self._clamp01(float(updates["emotional_significance"]))
        if "recurrence_count" in updates and updates["recurrence_count"] is not None:
            entry.recurrence_count = max(int(updates["recurrence_count"]), 1)
        if "is_active" in updates and updates["is_active"] is not None:
            entry.is_active = bool(updates["is_active"])

        entry.updated_at = datetime.utcnow()

        if previous_content != entry.content or previous_category != entry.category:
            embedding = (await self.llm.embed_texts([entry.content]))[0]
            entry.embedding_json = embedding
            if not entry.vector_id:
                entry.vector_id = f"memory-{entry.id}"
            await self.vector.upsert_memory_embedding(
                vector_id=entry.vector_id,
                content=entry.content,
                user_id=user_id,
                entry_id=entry.id,
                category=entry.category,
                is_active=entry.is_active,
                embedding=embedding,
            )

        if previous_content != entry.content or previous_category != entry.category:
            db.add(
                UserMemoryAuditLog(
                    entry_id=entry.id,
                    user_id=user_id,
                    old_content=previous_content,
                    new_content=entry.content,
                    old_category=previous_category,
                    new_category=entry.category,
                    reason="update",
                    changed_at=datetime.utcnow(),
                )
            )

        profile = await self.ensure_user_memory(db, user_id=user_id)
        profile.updated_at = datetime.utcnow()
        await self._refresh_profile_snapshot(db, profile=profile)
        await db.flush()
        return entry

    async def delete_memory_entry(self, db: AsyncSession, *, user_id: int, entry_id: int) -> None:
        entry = (
            await db.execute(
                select(UserMemoryEntry).where(
                    UserMemoryEntry.id == entry_id,
                    UserMemoryEntry.user_id == user_id,
                )
            )
        ).scalar_one_or_none()
        if entry is None:
            raise ValueError("Memory entry not found")

        previous_content = entry.content
        previous_category = entry.category
        entry.is_active = False
        entry.updated_at = datetime.utcnow()

        if entry.vector_id:
            await self.vector.delete_memory_embedding(vector_id=entry.vector_id)

        db.add(
            UserMemoryAuditLog(
                entry_id=entry.id,
                user_id=user_id,
                old_content=previous_content,
                new_content=None,
                old_category=previous_category,
                new_category=None,
                reason="delete",
                changed_at=datetime.utcnow(),
            )
        )

        profile = await self.ensure_user_memory(db, user_id=user_id)
        profile.updated_at = datetime.utcnow()
        await self._refresh_profile_snapshot(db, profile=profile)
        await db.flush()

    async def query_relevant_memories(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        context_embedding: list[float],
        top_k: int,
    ) -> list[UserMemoryEntry]:
        profile = await self.ensure_user_memory(db, user_id=user_id)
        if profile.is_paused:
            return []

        vector_hits = await self.vector.search_memory_entries(
            context_embedding=context_embedding,
            top_k=max(top_k * 4, top_k),
            user_id=user_id,
        )

        ordered_entry_ids: list[int] = []
        distance_map: dict[int, float] = {}
        for hit in vector_hits:
            entry_id = int(hit.get("entry_id", 0))
            if entry_id <= 0:
                continue
            if entry_id in distance_map:
                continue
            ordered_entry_ids.append(entry_id)
            distance_map[entry_id] = float(hit.get("distance", 1.0))

        if not ordered_entry_ids:
            fallback = (
                await db.execute(
                    select(UserMemoryEntry)
                    .where(UserMemoryEntry.user_id == user_id, UserMemoryEntry.is_active.is_(True))
                    .order_by(UserMemoryEntry.updated_at.desc(), UserMemoryEntry.id.desc())
                    .limit(top_k)
                )
            ).scalars().all()
            return list(fallback)

        rows = (
            await db.execute(
                select(UserMemoryEntry).where(
                    and_(
                        UserMemoryEntry.user_id == user_id,
                        UserMemoryEntry.is_active.is_(True),
                        UserMemoryEntry.id.in_(ordered_entry_ids),
                    )
                )
            )
        ).scalars().all()
        by_id = {row.id: row for row in rows}

        ranked: list[tuple[float, UserMemoryEntry]] = []
        for entry_id in ordered_entry_ids:
            row = by_id.get(entry_id)
            if row is None:
                continue
            semantic = 1.0 / (1.0 + max(distance_map.get(entry_id, 1.0), 0.0))
            recurrence_boost = min(row.recurrence_count / 5.0, 1.0)
            age_days = max((datetime.utcnow() - row.updated_at).days, 0)
            decay = self._decay_weight(age_days)
            final_score = (
                (0.55 * semantic)
                + (0.2 * self._clamp01(row.relevance_score))
                + (0.15 * recurrence_boost)
                + (0.1 * self._clamp01(row.emotional_significance))
            ) * decay
            ranked.append((final_score, row))

        ranked.sort(key=lambda item: item[0], reverse=True)
        seen_content: set[str] = set()
        selected: list[UserMemoryEntry] = []
        for _, row in ranked:
            token = self._dedup_token(row.category, row.content)
            if token in seen_content:
                continue
            seen_content.add(token)
            selected.append(row)
            if len(selected) >= top_k:
                break

        return selected

    async def list_memory_entries(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        category: str | None = None,
        include_inactive: bool = False,
    ) -> list[UserMemoryEntry]:
        query = select(UserMemoryEntry).where(UserMemoryEntry.user_id == user_id)
        if category:
            query = query.where(UserMemoryEntry.category == self._validate_category(category))
        if not include_inactive:
            query = query.where(UserMemoryEntry.is_active.is_(True))
        return list(
            (
                await db.execute(
                    query.order_by(UserMemoryEntry.updated_at.desc(), UserMemoryEntry.id.desc())
                )
            ).scalars().all()
        )

    async def set_memory_pause(self, db: AsyncSession, *, user_id: int, paused: bool) -> UserMemory:
        profile = await self.ensure_user_memory(db, user_id=user_id)
        profile.is_paused = paused
        profile.updated_at = datetime.utcnow()
        await db.flush()
        return profile

    async def memory_trends(self, db: AsyncSession, *, user_id: int, days: int = 30) -> list[dict[str, Any]]:
        cutoff = datetime.utcnow() - timedelta(days=max(days, 1))
        rows = (
            await db.execute(
                select(UserMemoryEntry).where(
                    UserMemoryEntry.user_id == user_id,
                    UserMemoryEntry.created_at >= cutoff,
                )
            )
        ).scalars().all()

        bucket: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
        for row in rows:
            day = row.created_at.date().isoformat()
            bucket[day][row.category] += 1

        points: list[dict[str, Any]] = []
        for day in sorted(bucket.keys()):
            by_category = dict(sorted(bucket[day].items()))
            points.append(
                {
                    "date": day,
                    "total": sum(by_category.values()),
                    "by_category": by_category,
                }
            )
        return points

    async def upsert_from_conversation_summary(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        conversation_id: int,
        summary: str,
        transcript: str,
    ) -> None:
        profile = await self.ensure_user_memory(db, user_id=user_id)
        if profile.is_paused:
            return

        normalized_summary = self._clean_content(summary)
        if not normalized_summary:
            profile.last_summarized_at = datetime.utcnow()
            profile.updated_at = datetime.utcnow()
            await db.flush()
            return

        existing = (
            await db.execute(
                select(UserMemoryEntry).where(
                    UserMemoryEntry.user_id == user_id,
                    UserMemoryEntry.source_conversation_id == conversation_id,
                    UserMemoryEntry.is_active.is_(True),
                )
            )
        ).scalar_one_or_none()

        if existing is not None:
            await self.update_memory_entry(
                db,
                user_id=user_id,
                entry_id=existing.id,
                updates={
                    "content": normalized_summary,
                    "category": MemoryCategory.PREFERENCE.value,
                    "relevance_score": 0.75,
                    "emotional_significance": 0.6,
                    "recurrence_count": max(existing.recurrence_count, 1),
                },
            )
        else:
            await self.add_memory_entry(
                db,
                user_id=user_id,
                content=normalized_summary,
                category=MemoryCategory.PREFERENCE.value,
                source_conversation_id=conversation_id,
                relevance_score=0.75,
                emotional_significance=0.6,
                recurrence_count=1,
            )

        profile.last_summarized_at = datetime.utcnow()
        profile.updated_at = datetime.utcnow()
        await self._refresh_profile_snapshot(db, profile=profile)
        await db.flush()

    async def _refresh_profile_snapshot(self, db: AsyncSession, *, profile: UserMemory) -> None:
        entries = (
            await db.execute(
                select(UserMemoryEntry)
                .where(UserMemoryEntry.user_id == profile.user_id, UserMemoryEntry.is_active.is_(True))
                .order_by(UserMemoryEntry.updated_at.desc(), UserMemoryEntry.id.desc())
                .limit(120)
            )
        ).scalars().all()

        summaries = [entry.content for entry in entries if entry.content.strip()]

        profile.habits_json = []
        profile.emotions_json = []
        profile.goals_json = []
        profile.context_json = {
            "summary_context_window": self._unique_preserve_order(summaries)[:20],
            "memory_count": len(entries),
        }

        await db.flush()

    @staticmethod
    def _unique_preserve_order(values: list[str]) -> list[str]:
        seen: set[str] = set()
        out: list[str] = []
        for value in values:
            key = value.strip().lower()
            if not key or key in seen:
                continue
            seen.add(key)
            out.append(value.strip())
        return out

    @staticmethod
    def _clean_content(content: str) -> str:
        return " ".join(content.replace("\n", " ").split())[:3000].strip()

    @staticmethod
    def _validate_category(category: str) -> str:
        value = str(category).strip().lower()
        allowed = {item.value for item in MemoryCategory}
        if value not in allowed:
            raise ValueError("Invalid memory category")
        return value

    @staticmethod
    def _clamp01(value: float) -> float:
        if value < 0.0:
            return 0.0
        if value > 1.0:
            return 1.0
        return value

    def _decay_weight(self, age_days: int) -> float:
        half_life = max(self.settings.memory_decay_half_life_days, 1)
        decay = math.exp(-(math.log(2) * age_days) / half_life)
        return max(decay, 0.2)

    @staticmethod
    def _dedup_token(category: str, content: str) -> str:
        return f"{category}:{content.strip().lower()}"
