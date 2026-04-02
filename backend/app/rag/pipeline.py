from __future__ import annotations

import asyncio
import logging
from collections.abc import AsyncGenerator
from dataclasses import dataclass
from datetime import datetime, UTC
from typing import Any

import httpx
from sqlalchemy import func
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.time_patterns import TimePatternAnalytics
from app.config import get_settings
from app.models.conversation import Conversation
from app.models.message import Message, MessageRole
from app.models.message_analysis import MessageAnalysis
from app.schemas.analysis import EmotionDetectionResult, HabitDetectionResult
from app.services.chat_memory_service import ChatMemoryService
from app.services.emotion_service import EmotionService
from app.services.graph_service import GraphService
from app.services.habit_service import HabitService
from app.services.llm_service import LLMService
from app.services.vector_service import VectorService

logger = logging.getLogger(__name__)


@dataclass
class PreparedGenerationContext:
    """State produced by retrieval/context steps before assistant generation starts."""

    conversation_id: int
    user_id: int
    user_message_id: int
    user_timestamp: datetime
    user_text: str
    emotions: list[dict[str, Any]]
    habits: list[dict[str, Any]]
    response_max_tokens: int | None
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
        chat_memory_service: ChatMemoryService | None = None,
    ) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.emotion = emotion_service or EmotionService(self.llm)
        self.habit = habit_service or HabitService(self.llm)
        self.vector = vector_service or VectorService(self.llm)
        self.graph = graph_service or GraphService()
        self.analytics = analytics_service or TimePatternAnalytics()
        self.memory = chat_memory_service or ChatMemoryService(self.llm)
        self.placeholder_titles = {"New Reflection", "New Conversation"}
        self.max_generated_title_words = 2

    async def run(self, db: AsyncSession, conversation_id: int, user_id: int, user_text: str) -> dict:
        context = await self._prepare_generation_context(
            db=db,
            conversation_id=conversation_id,
            user_id=user_id,
            user_text=user_text,
        )
        assistant_text = await self.llm.generate_chat(context.final_prompt, max_tokens=context.response_max_tokens)
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
            async for token in self.llm.stream_chat_tokens(context.final_prompt, max_tokens=context.response_max_tokens):
                streamed_parts.append(token)
                yield {"type": "token", "token": token}
        except asyncio.CancelledError as exc:
            stream_error = exc
        except Exception as exc:  # noqa: BLE001
            stream_error = exc

        assistant_text = "".join(streamed_parts).strip()
        if not assistant_text:
            if stream_error is None:
                assistant_text = await self.llm.generate_chat(
                    context.final_prompt,
                    max_tokens=context.response_max_tokens,
                )
            else:
                # If streaming fails before any content arrives, attempt one full completion
                # to avoid surfacing a disconnect banner for recoverable provider hiccups.
                try:
                    assistant_text = await self.llm.generate_chat(
                        context.final_prompt,
                        max_tokens=context.response_max_tokens,
                    )
                except Exception as recovery_exc:  # noqa: BLE001
                    logger.warning(
                        "Streaming recovery generation failed for conversation %s user %s: %s",
                        context.conversation_id,
                        context.user_id,
                        recovery_exc,
                    )
                else:
                    stream_error = None

        assistant_message = await self._finalize_assistant_response(
            db=db,
            context=context,
            assistant_text=assistant_text,
        )

        if stream_error is not None:
            error_message, error_code, retryable = self._classify_stream_error(stream_error)
            logger.warning(
                "Streaming interrupted for conversation %s user %s (%s): %s",
                context.conversation_id,
                context.user_id,
                error_code,
                stream_error,
            )
            yield {
                "type": "error",
                "message": error_message,
                "error_code": error_code,
                "retryable": retryable,
                "partial_saved": True,
                "conversation_id": context.conversation_id,
                "assistant_message_id": assistant_message.id,
                "response": assistant_text,
                "timestamp": assistant_message.timestamp,
            }
            return

        yield {
            "type": "message_end",
            "conversation_id": context.conversation_id,
            "assistant_message_id": assistant_message.id,
            "response": assistant_text,
            "timestamp": assistant_message.timestamp,
        }

    @staticmethod
    def _classify_stream_error(exc: Exception) -> tuple[str, str, bool]:
        if isinstance(exc, asyncio.CancelledError):
            return (
                "The stream was cancelled. Partial response was saved.",
                "stream_cancelled",
                True,
            )

        if isinstance(exc, (TimeoutError, asyncio.TimeoutError, httpx.TimeoutException)):
            return (
                "The model took too long to continue streaming. Partial response was saved.",
                "stream_timeout",
                True,
            )

        if isinstance(exc, httpx.TransportError):
            return (
                "The connection dropped while streaming. Partial response was saved.",
                "stream_transport_error",
                True,
            )

        return (
            "The response connection was interrupted. Partial response was saved.",
            "stream_error",
            True,
        )

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

        now = user_message.timestamp or datetime.now(UTC)
        await self.vector.upsert_message_embedding(
            vector_id=f"msg-{user_message.id}",
            content=user_text,
            user_id=user_id,
            conversation_id=conversation_id,
            message_id=user_message.id,
            timestamp=now,
            emotions=[],
            habits=[],
            role=MessageRole.USER.value,
        )

        if self._is_small_talk_message(user_text):
            emotions = [{"label": "neutral", "confidence": 0.6}]
            habits: list[dict[str, Any]] = []
            analysis = MessageAnalysis(
                message_id=user_message.id,
                emotions_json={"emotions": emotions},
                habits_json={"habits": habits},
                detected_topics_json={"topics": ["small_talk"]},
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

            return PreparedGenerationContext(
                conversation_id=conversation_id,
                user_id=user_id,
                user_message_id=user_message.id,
                user_timestamp=now,
                user_text=user_text,
                emotions=emotions,
                habits=habits,
                response_max_tokens=64,
                final_prompt=self._build_small_talk_prompt(user_text),
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

        recall_intent = self._is_history_recall_query(user_text)
        supportive_mode = self._needs_distress_support(user_text, emotions)
        retrieval_top_k = self.settings.retrieval_top_k_messages + (3 if recall_intent else 0)

        similar_messages = await self.vector.search_similar_messages(
            user_text,
            retrieval_top_k,
            user_id=user_id,
        )
        kb_docs = await self.vector.search_knowledge(user_text, self.settings.retrieval_top_k_kb)
        emotion_stats = await self.analytics.emotion_stats(db, user_id=user_id)
        habit_stats = await self.analytics.habit_stats(db, user_id=user_id)
        time_patterns = await self.analytics.time_patterns(db, user_id=user_id)
        habit_emotion_links = await self.analytics.habit_emotion_links(db, user_id=user_id, min_count=2, top_n=12)
        recent_memories = await self.memory.get_recent_memories(db, user_id=user_id)

        history_rows = (
            await db.execute(
                select(Message.role, Message.content)
                .where(Message.conversation_id == conversation_id)
                .order_by(Message.timestamp.desc())
                .limit(8)
            )
        ).all()
        history_block = "\n".join([f"{row.role.value}: {row.content}" for row in reversed(history_rows)])

        cross_conversation_history_block = ""
        if recall_intent:
            all_history_rows = (
                await db.execute(
                    select(Conversation.id, Message.role, Message.content, Message.timestamp)
                    .join(Conversation, Conversation.id == Message.conversation_id)
                    .where(Conversation.user_id == user_id)
                    .order_by(Message.timestamp.desc())
                    .limit(14)
                )
            ).all()
            cross_conversation_history_block = "\n".join(
                [
                    f"conv#{row.id} {row.timestamp.isoformat()} {row.role.value}: {row.content}"
                    for row in reversed(all_history_rows)
                ]
            )

        final_prompt = self._build_prompt(
            user_text=user_text,
            history_block=history_block,
            cross_conversation_history_block=cross_conversation_history_block,
            similar_messages=similar_messages,
            kb_docs=kb_docs,
            emotion_stats=emotion_stats,
            habit_stats=habit_stats,
            time_patterns=time_patterns,
            habit_emotion_links=habit_emotion_links,
            recent_memories=recent_memories,
            emotions=emotions,
            habits=habits,
            recall_intent=recall_intent,
            supportive_mode=supportive_mode,
        )

        return PreparedGenerationContext(
            conversation_id=conversation_id,
            user_id=user_id,
            user_message_id=user_message.id,
            user_timestamp=now,
            user_text=user_text,
            emotions=emotions,
            habits=habits,
            response_max_tokens=160,
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
            user_id=context.user_id,
            conversation_id=context.conversation_id,
            message_id=assistant_message.id,
            timestamp=assistant_message.timestamp or datetime.now(UTC),
            emotions=context.emotions,
            habits=context.habits,
            role=MessageRole.ASSISTANT.value,
        )

        await self._maybe_generate_conversation_title(
            db=db,
            conversation_id=context.conversation_id,
            latest_user_text=context.user_text,
            latest_assistant_text=assistant_text,
        )

        await db.commit()
        return assistant_message

    async def _maybe_generate_conversation_title(
        self,
        *,
        db: AsyncSession,
        conversation_id: int,
        latest_user_text: str,
        latest_assistant_text: str,
    ) -> None:
        conversation = (await db.execute(select(Conversation).where(Conversation.id == conversation_id))).scalar_one_or_none()
        if conversation is None or conversation.title not in self.placeholder_titles:
            return

        message_count = (await db.execute(select(func.count(Message.id)).where(Message.conversation_id == conversation_id))).scalar_one()
        if message_count != 2:
            return

        first_exchange_rows = (
            await db.execute(
                select(Message.role, Message.content)
                .where(Message.conversation_id == conversation_id)
                .order_by(Message.timestamp.asc(), Message.id.asc())
                .limit(2)
            )
        ).all()
        if len(first_exchange_rows) != 2:
            return

        role_sequence = [row.role for row in first_exchange_rows]
        if role_sequence != [MessageRole.USER, MessageRole.ASSISTANT]:
            return

        first_user_text = first_exchange_rows[0].content.strip() or latest_user_text
        first_assistant_text = first_exchange_rows[1].content.strip() or latest_assistant_text
        prompt = self._build_title_prompt(
            first_user_text=first_user_text,
            first_assistant_text=first_assistant_text,
        )

        try:
            raw_title = await self.llm.generate_chat(prompt, temperature=0.1, max_tokens=24)
        except Exception:  # noqa: BLE001
            return

        normalized_title = self._normalize_generated_title(raw_title)
        if not normalized_title:
            normalized_title = self._fallback_title(first_user_text)

        if normalized_title:
            conversation.title = normalized_title[:255]

    @staticmethod
    def _build_title_prompt(*, first_user_text: str, first_assistant_text: str) -> str:
        return (
            "You write concise reflection titles for journal conversations.\n"
            "Create exactly one title that summarizes the main theme of this exchange.\n"
            "Constraints:\n"
            "- 1 to 2 words\n"
            "- one line only\n"
            "- no quotation marks\n"
            "- no trailing punctuation\n\n"
            f"User message:\n{first_user_text}\n\n"
            f"Assistant reply:\n{first_assistant_text}\n\n"
            "Return only the title text."
        )

    def _normalize_generated_title(self, title: str) -> str:
        single_line = " ".join(title.replace("\n", " ").split()).strip(" '\"`.,;:!?-_")
        if not single_line:
            return ""

        words = single_line.split()
        if len(words) > self.max_generated_title_words:
            words = words[: self.max_generated_title_words]
        return " ".join(words)

    def _fallback_title(self, user_text: str) -> str:
        words = [word for word in user_text.replace("\n", " ").split() if word]
        if not words:
            return "New Reflection"
        return " ".join(words[: self.max_generated_title_words]).strip(" '\"`.,;:!?-_")

    def _build_prompt(
        self,
        *,
        user_text: str,
        history_block: str,
        cross_conversation_history_block: str,
        similar_messages: list[str],
        kb_docs: list[str],
        emotion_stats: list[dict],
        habit_stats: list[dict],
        time_patterns: list[dict],
        habit_emotion_links: list[dict],
        recent_memories: list[str],
        emotions: list[dict],
        habits: list[dict],
        recall_intent: bool,
        supportive_mode: bool,
    ) -> str:
        memory_block = "\n".join(f"- {summary}" for summary in recent_memories) if recent_memories else "- No saved user memories yet."
        quote_rule = (
            "The user appears to be asking about past chats. Prioritize historical evidence from the provided history. "
            "Summarize findings unless the user explicitly asks for direct quotes or timestamps."
            if recall_intent
            else "Summarize naturally. Provide direct quotes or timestamps only if the user asks for them."
        )

        cross_history_section = (
            f"User history across conversations (same user only):\n{cross_conversation_history_block}\n\n"
            if recall_intent
            else ""
        )
        response_style = (
            "Generate a personalized response with:\n"
            "1) brief emotional validation\n"
            "2) one actionable coping or habit suggestion\n"
            "3) one optional follow-up question\n"
            if supportive_mode
            else "Respond naturally and directly to the user without forced therapeutic framing. "
            "Do not require a follow-up question if it does not fit.\n"
        )

        return (
            "You are MindPal, a supportive mental health assistant. Provide practical, compassionate, "
            "non-clinical guidance and suggest professional help for crisis situations.\n\n"
            f"User memories:\n{memory_block}\n\n"
            f"Recent conversation history:\n{history_block}\n\n"
            f"{cross_history_section}"
            f"Detected current emotions: {emotions}\n"
            f"Detected habits/behaviors: {habits}\n\n"
            f"Similar past messages:\n{similar_messages}\n\n"
            f"Knowledge base context:\n{kb_docs}\n\n"
            f"Emotion trends:\n{emotion_stats}\n"
            f"Habit trends:\n{habit_stats}\n"
            f"Time-based patterns:\n{time_patterns}\n\n"
            f"Habit-emotion associations (historical co-occurrence, not causation):\n{habit_emotion_links}\n\n"
            f"Current user message:\n{user_text}\n\n"
            f"{response_style}"
            f"{quote_rule}\n"
            "If historical evidence is missing, say so clearly and ask a clarifying question.\n"
            "Use current detections first, then reference historical associations only as pattern signals. "
            "Do not present associations as medical or causal conclusions.\n"
            "Keep responses to 1-2 short sentences unless the user asks for more detail."
        )

    @staticmethod
    def _is_history_recall_query(user_text: str) -> bool:
        lowered = user_text.lower()
        recall_markers = [
            "before",
            "past",
            "earlier",
            "previous",
            "last time",
            "what did i say",
            "have we talked",
            "remember",
            "history",
        ]
        return any(marker in lowered for marker in recall_markers)

    @staticmethod
    def _is_small_talk_message(user_text: str) -> bool:
        normalized = " ".join(user_text.lower().split()).strip(".,!?;:'\"`")
        small_talk = {
            "hi",
            "hey",
            "hello",
            "thanks",
            "thank you",
            "thx",
            "ok",
            "okay",
        }
        return normalized in small_talk

    @staticmethod
    def _build_small_talk_prompt(user_text: str) -> str:
        return (
            "You are MindPal, a supportive assistant.\n\n"
            f"User message: {user_text}\n"
            "Reply with exactly one short, warm sentence and no follow-up question."
        )

    @staticmethod
    def _needs_distress_support(user_text: str, emotions: list[dict[str, Any]]) -> bool:
        distress_emotions = {"anxiety", "stress", "sadness", "anger", "fear"}
        if any(item.get("label") in distress_emotions for item in emotions):
            return True

        lowered = user_text.lower()
        distress_markers = [
            "panic",
            "overwhelmed",
            "can't cope",
            "cannot cope",
            "i feel terrible",
            "i'm not okay",
            "depressed",
            "hopeless",
        ]
        return any(marker in lowered for marker in distress_markers)
