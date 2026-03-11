from __future__ import annotations

import asyncio
from collections.abc import AsyncGenerator
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.time_patterns import TimePatternAnalytics
from app.config import get_settings
from app.models.message import Message, MessageRole
from app.models.message_analysis import MessageAnalysis
from app.schemas.analysis import EmotionDetectionResult, HabitDetectionResult
from app.services.emotion_service import EmotionService
from app.services.graph_service import GraphService
from app.services.habit_service import HabitService
from app.services.llm_service import LLMService
from app.services.vector_service import VectorService


@dataclass
class PreparedGenerationContext:
    """State produced by retrieval/context steps before assistant generation starts."""

    conversation_id: int
    user_message_id: int
    user_timestamp: datetime
    emotions: list[dict[str, Any]]
    habits: list[dict[str, Any]]
    final_prompt: str


class RAGPipeline:
    """Orchestrates full MindPal RAG chat flow."""

    def __init__(
        self,
        llm_service: LLMService | None = None,
        emotion_service: EmotionService | None = None,
        habit_service: HabitService | None = None,
        vector_service: VectorService | None = None,
        graph_service: GraphService | None = None,
        analytics_service: TimePatternAnalytics | None = None,
    ) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.emotion = emotion_service or EmotionService(self.llm)
        self.habit = habit_service or HabitService(self.llm)
        self.vector = vector_service or VectorService(self.llm)
        self.graph = graph_service or GraphService()
        self.analytics = analytics_service or TimePatternAnalytics()

    async def run(self, db: AsyncSession, conversation_id: int, user_id: int, user_text: str) -> dict:
        context = await self._prepare_generation_context(
            db=db,
            conversation_id=conversation_id,
            user_id=user_id,
            user_text=user_text,
        )
        assistant_text = await self.llm.generate_chat(context.final_prompt)
        assistant_message = await self._finalize_assistant_response(
            db=db,
            context=context,
            assistant_text=assistant_text,
        )

        return {
            "conversation_id": conversation_id,
            "user_message_id": context.user_message_id,
            "assistant_message_id": assistant_message.id,
            "response": assistant_text,
            "timestamp": assistant_message.timestamp,
        }

    async def run_stream(
        self,
        db: AsyncSession,
        conversation_id: int,
        user_id: int,
        user_text: str,
    ) -> AsyncGenerator[dict[str, Any], None]:
        """Run full RAG flow, then stream assistant tokens and persist final/partial output.

        Retrieval and context assembly still complete before generation begins; only the
        response transport layer changes to improve perceived responsiveness.
        """
        context = await self._prepare_generation_context(
            db=db,
            conversation_id=conversation_id,
            user_id=user_id,
            user_text=user_text,
        )

        yield {
            "type": "message_start",
            "conversation_id": context.conversation_id,
            "user_message_id": context.user_message_id,
        }

        streamed_parts: list[str] = []
        stream_error: Exception | None = None

        try:
            async for token in self.llm.stream_chat_tokens(context.final_prompt):
                streamed_parts.append(token)
                yield {"type": "token", "token": token}
        except asyncio.CancelledError as exc:
            stream_error = exc
        except Exception as exc:  # noqa: BLE001
            stream_error = exc

        assistant_text = "".join(streamed_parts).strip()
        assistant_message = await self._finalize_assistant_response(
            db=db,
            context=context,
            assistant_text=assistant_text,
        )

        if stream_error is not None:
            yield {
                "type": "error",
                "message": "The stream disconnected. Partial response was saved.",
                "conversation_id": context.conversation_id,
                "assistant_message_id": assistant_message.id,
                "timestamp": assistant_message.timestamp,
            }
            return

        yield {
            "type": "message_end",
            "conversation_id": context.conversation_id,
            "assistant_message_id": assistant_message.id,
            "timestamp": assistant_message.timestamp,
        }

    async def _prepare_generation_context(
        self,
        *,
        db: AsyncSession,
        conversation_id: int,
        user_id: int,
        user_text: str,
    ) -> PreparedGenerationContext:
        # Save user message before retrieval so history and analytics remain consistent.
        user_message = Message(conversation_id=conversation_id, role=MessageRole.USER, content=user_text)
        db.add(user_message)
        await db.flush()

        now = user_message.timestamp or datetime.utcnow()
        await self.vector.upsert_message_embedding(
            vector_id=f"msg-{user_message.id}",
            content=user_text,
            conversation_id=conversation_id,
            message_id=user_message.id,
            timestamp=now,
            emotions=[],
            habits=[],
            role=MessageRole.USER.value,
        )

        emotion_result: EmotionDetectionResult = await self.emotion.detect_emotions(user_text)
        habit_result: HabitDetectionResult = await self.habit.detect_habits(user_text)
        emotions = emotion_result.model_dump()["emotions"]
        habits = habit_result.model_dump()["habits"]

        analysis = MessageAnalysis(
            message_id=user_message.id,
            emotions_json=emotion_result.model_dump(),
            habits_json=habit_result.model_dump(),
            detected_topics_json={"topics": []},
            time_of_day=str(now.hour),
            day_of_week=now.strftime("%A"),
        )
        db.add(analysis)

        self.graph.update_relationships(
            user_id=user_id,
            message_id=user_message.id,
            emotions=emotions,
            habits=habits,
        )

        similar_messages = await self.vector.search_similar_messages(user_text, self.settings.retrieval_top_k_messages)
        kb_docs = await self.vector.search_knowledge(user_text, self.settings.retrieval_top_k_kb)
        emotion_stats = await self.analytics.emotion_stats(db, user_id=user_id)
        habit_stats = await self.analytics.habit_stats(db, user_id=user_id)
        time_patterns = await self.analytics.time_patterns(db, user_id=user_id)
        habit_emotion_links = await self.analytics.habit_emotion_links(db, user_id=user_id, min_count=2, top_n=12)

        history_rows = (
            await db.execute(
                select(Message.role, Message.content)
                .where(Message.conversation_id == conversation_id)
                .order_by(Message.timestamp.desc())
                .limit(8)
            )
        ).all()
        history_block = "\n".join([f"{row.role.value}: {row.content}" for row in reversed(history_rows)])

        final_prompt = self._build_prompt(
            user_text=user_text,
            history_block=history_block,
            similar_messages=similar_messages,
            kb_docs=kb_docs,
            emotion_stats=emotion_stats,
            habit_stats=habit_stats,
            time_patterns=time_patterns,
            habit_emotion_links=habit_emotion_links,
            emotions=emotions,
            habits=habits,
        )

        return PreparedGenerationContext(
            conversation_id=conversation_id,
            user_message_id=user_message.id,
            user_timestamp=now,
            emotions=emotions,
            habits=habits,
            final_prompt=final_prompt,
        )

    async def _finalize_assistant_response(
        self,
        *,
        db: AsyncSession,
        context: PreparedGenerationContext,
        assistant_text: str,
    ) -> Message:
        assistant_message = Message(
            conversation_id=context.conversation_id,
            role=MessageRole.ASSISTANT,
            content=assistant_text,
        )
        db.add(assistant_message)
        await db.flush()

        await self.vector.upsert_message_embedding(
            vector_id=f"msg-{assistant_message.id}",
            content=assistant_text,
            conversation_id=context.conversation_id,
            message_id=assistant_message.id,
            timestamp=assistant_message.timestamp or datetime.utcnow(),
            emotions=context.emotions,
            habits=context.habits,
            role=MessageRole.ASSISTANT.value,
        )

        await db.commit()
        return assistant_message

    def _build_prompt(
        self,
        *,
        user_text: str,
        history_block: str,
        similar_messages: list[str],
        kb_docs: list[str],
        emotion_stats: list[dict],
        habit_stats: list[dict],
        time_patterns: list[dict],
        habit_emotion_links: list[dict],
        emotions: list[dict],
        habits: list[dict],
    ) -> str:
        return (
            "You are MindPal, a supportive mental health assistant. Provide practical, compassionate, "
            "non-clinical guidance and suggest professional help for crisis situations.\n\n"
            f"Current user message:\n{user_text}\n\n"
            f"Recent conversation history:\n{history_block}\n\n"
            f"Detected current emotions: {emotions}\n"
            f"Detected habits/behaviors: {habits}\n\n"
            f"Similar past messages:\n{similar_messages}\n\n"
            f"Knowledge base context:\n{kb_docs}\n\n"
            f"Emotion trends:\n{emotion_stats}\n"
            f"Habit trends:\n{habit_stats}\n"
            f"Time-based patterns:\n{time_patterns}\n\n"
            f"Habit-emotion associations (historical co-occurrence, not causation):\n{habit_emotion_links}\n\n"
            "Generate a personalized response with:\n"
            "1) brief emotional validation\n"
            "2) one actionable coping or habit suggestion\n"
            "3) one optional follow-up question\n"
            "Use current detections first, then reference historical associations only as pattern signals. "
            "Do not present associations as medical or causal conclusions.\n"
            "Keep response under 180 words."
        )
