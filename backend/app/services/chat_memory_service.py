from __future__ import annotations

import logging
from datetime import datetime, UTC

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.conversation import Conversation
from app.models.message import Message, MessageRole
from app.models.user_chat_memory import UserChatMemory
from app.services.llm_service import LLMService

logger = logging.getLogger(__name__)


class ChatMemoryService:
    """Stores short long-term summaries for completed user chats."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()

    async def get_recent_memories(self, db: AsyncSession, *, user_id: int, limit: int | None = None) -> list[str]:
        effective_limit = limit or self.settings.memory_max_items
        rows = (
            await db.execute(
                select(UserChatMemory.summary)
                .where(UserChatMemory.user_id == user_id)
                .order_by(UserChatMemory.created_at.desc(), UserChatMemory.id.desc())
                .limit(effective_limit)
            )
        ).scalars().all()
        return list(rows)

    async def summarize_and_store_conversation(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        conversation_id: int,
        refresh_existing: bool = False,
    ) -> UserChatMemory | None:
        existing = (
            await db.execute(select(UserChatMemory).where(UserChatMemory.chat_id == conversation_id))
        ).scalar_one_or_none()
        if existing is not None and not refresh_existing:
            return existing

        if existing is not None and refresh_existing:
            latest_message_at = await self._latest_message_timestamp(db, conversation_id=conversation_id)
            if latest_message_at is None or latest_message_at <= existing.created_at:
                return existing

        rows = (
            await db.execute(
                select(Message.role, Message.content)
                .join(Conversation, Conversation.id == Message.conversation_id)
                .where(Conversation.id == conversation_id, Conversation.user_id == user_id)
                .order_by(Message.timestamp.asc(), Message.id.asc())
            )
        ).all()
        if not rows:
            return existing

        transcript = self._build_transcript(rows)
        if self._should_skip_summary(transcript):
            return existing

        summary = await self._generate_summary(transcript)
        if not summary:
            return existing

        if existing is not None:
            existing.summary = summary
            existing.created_at = datetime.now(UTC)
            await db.flush()
            await self.prune_user_memories(db, user_id=user_id)
            return existing

        memory = UserChatMemory(user_id=user_id, chat_id=conversation_id, summary=summary)
        db.add(memory)
        await db.flush()
        await self.prune_user_memories(db, user_id=user_id)
        return memory

    async def _latest_message_timestamp(self, db: AsyncSession, *, conversation_id: int) -> datetime | None:
        return (
            await db.execute(select(func.max(Message.timestamp)).where(Message.conversation_id == conversation_id))
        ).scalar_one_or_none()

    async def prune_user_memories(self, db: AsyncSession, *, user_id: int) -> None:
        rows = (
            await db.execute(
                select(UserChatMemory)
                .where(UserChatMemory.user_id == user_id)
                .order_by(UserChatMemory.created_at.desc(), UserChatMemory.id.desc())
                .offset(self.settings.memory_max_items)
            )
        ).scalars().all()

        for row in rows:
            await db.delete(row)

    async def backfill_closed_conversations(self, db: AsyncSession, *, user_id: int | None = None) -> int:
        query = select(Conversation.id, Conversation.user_id).where(Conversation.is_closed.is_(True)).order_by(Conversation.id.asc())
        if user_id is not None:
            query = query.where(Conversation.user_id == user_id)

        created_count = 0
        for conversation_id, conversation_user_id in (await db.execute(query)).all():
            existing = (
                await db.execute(select(UserChatMemory.id).where(UserChatMemory.chat_id == conversation_id))
            ).scalar_one_or_none()
            if existing is not None:
                continue

            memory = await self.summarize_and_store_conversation(
                db,
                user_id=conversation_user_id,
                conversation_id=conversation_id,
            )
            if memory is not None:
                created_count += 1

        return created_count

    async def _generate_summary(self, transcript: str) -> str:
        prompt = (
            "Summarize important personal information from this conversation in 2-3 sentences. "
            "Focus on emotions, struggles, habits, goals, and life events that may help an AI assistant remember the user later.\n"
            "Constraints:\n"
            "- Mention only durable or useful personal context\n"
            "- Do not quote the conversation\n"
            "- Do not mention the assistant\n"
            "- Return plain text only\n\n"
            f"Conversation transcript:\n{transcript}\n\n"
            "Memory summary:"
        )
        summary = await self.llm.generate_chat(
            prompt,
            temperature=self.settings.memory_summary_temperature,
            max_tokens=self.settings.memory_summary_max_tokens,
        )
        return " ".join(summary.split())

    def _should_skip_summary(self, transcript: str) -> bool:
        return len(transcript.strip()) < self.settings.memory_summary_min_chars

    @staticmethod
    def _build_transcript(rows: list[tuple[MessageRole, str]]) -> str:
        return "\n".join(f"{role.value}: {content.strip()}" for role, content in rows if content.strip())
