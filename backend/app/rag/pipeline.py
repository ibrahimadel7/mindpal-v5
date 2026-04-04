from __future__ import annotations

import asyncio
import logging
import re
from collections.abc import AsyncGenerator
from dataclasses import dataclass
from datetime import datetime
from typing import Any

import httpx
from sqlalchemy import func
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.agents.analysis_service import AnalysisService
from app.agents.data_preprocessor import DataPreprocessor
from app.agents.intervention_engine import InterventionControl
from app.analytics.time_patterns import TimePatternAnalytics
from app.config import get_settings
from app.models.conversation import Conversation
from app.models.message import Message, MessageRole
from app.models.message_analysis import MessageAnalysis
from app.schemas.analysis import EmotionDetectionResult, HabitDetectionResult
from app.schemas.thinking import ReasoningOutput
from app.services.chat_memory_service import ChatMemoryService
from app.services.context_window_service import ContextWindowService
from app.services.emotion_service import EmotionService
from app.services.graph_service import GraphService
from app.services.habit_service import HabitService
from app.services.llm_service import LLMService
from app.services.memory_service import MemoryService
from app.services.thinking_service import ThinkingService
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
    reasoning_output: ReasoningOutput | None
    response_plan: "ResponsePlan"
    response_max_tokens: int | None
    final_prompt: str


@dataclass(frozen=True)
class ResponsePlan:
    """Compact, deterministic guidance for shaping the assistant reply."""

    label: str
    min_sentences: int
    max_sentences: int
    max_tokens: int
    acknowledge_user: bool
    ask_follow_up: bool
    use_bullets: bool
    tone: str
    focus: str


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
        memory_service: MemoryService | None = None,
        analysis_service: AnalysisService | None = None,
        context_window_service: ContextWindowService | None = None,
        thinking_service: ThinkingService | None = None,
    ) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.emotion = emotion_service or EmotionService(self.llm)
        self.habit = habit_service or HabitService(self.llm)
        self.vector = vector_service or VectorService(self.llm)
        self.graph = graph_service or GraphService()
        self.analytics = analytics_service or TimePatternAnalytics()
        self.memory = chat_memory_service or ChatMemoryService(self.llm)
        self.persistent_memory = memory_service or MemoryService(self.llm, self.vector)
        self.analysis = analysis_service or AnalysisService(self.llm)
        self.thinking = thinking_service or ThinkingService(self.llm)
        self.context_window = context_window_service or ContextWindowService(
            self.llm,
            self.memory,
            self.persistent_memory,
            self.vector,
        )
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
        assistant_text = self._normalize_assistant_text(assistant_text, context.response_plan)
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

        assistant_text = self._normalize_assistant_text("".join(streamed_parts), context.response_plan)
        if not assistant_text:
            if stream_error is None:
                assistant_text = await self.llm.generate_chat(
                    context.final_prompt,
                    max_tokens=context.response_max_tokens,
                )
                assistant_text = self._normalize_assistant_text(assistant_text, context.response_plan)
            else:
                # If streaming fails before any content arrives, attempt one full completion
                # to avoid surfacing a disconnect banner for recoverable provider hiccups.
                try:
                    assistant_text = await self.llm.generate_chat(
                        context.final_prompt,
                        max_tokens=context.response_max_tokens,
                    )
                    assistant_text = self._normalize_assistant_text(assistant_text, context.response_plan)
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

        now = user_message.timestamp or datetime.utcnow()
        small_talk = self._is_small_talk_message(user_text)
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

        if small_talk:
            emotions = [{"label": "neutral", "confidence": 0.6}]
            habits: list[dict[str, Any]] = []
            response_plan = self._plan_response(
                user_text=user_text,
                emotions=emotions,
                habits=habits,
                recall_intent=False,
                supportive_mode=False,
            )
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
                reasoning_output=None,
                response_plan=response_plan,
                response_max_tokens=response_plan.max_tokens,
                final_prompt=self._build_small_talk_prompt(user_text, response_plan=response_plan),
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
        retrieval_tags = self._extract_retrieval_tags(user_text=user_text, emotions=emotions, habits=habits)
        include_crisis = self._needs_crisis_resource(user_text=user_text, emotions=emotions)
        kb_entries = await self.vector.search_knowledge_entries(
            user_text,
            max(self.settings.retrieval_top_k_kb, 5),
            tags=retrieval_tags,
            include_crisis=include_crisis,
        )
        kb_docs = [entry["content"] for entry in kb_entries]
        emotion_stats = await self.analytics.emotion_stats(db, user_id=user_id)
        habit_stats = await self.analytics.habit_stats(db, user_id=user_id)
        time_patterns = await self.analytics.time_patterns(db, user_id=user_id)
        habit_emotion_links = await self.analytics.habit_emotion_links(db, user_id=user_id, min_count=2, top_n=12)
        recent_memories = await self.memory.get_recent_memories(db, user_id=user_id)
        persistent_memories: list[dict[str, Any]] = []
        if self.settings.memory_injection_enabled:
            context_embedding = (await self.llm.embed_texts([user_text]))[0]
            relevant_entries = await self.persistent_memory.query_relevant_memories(
                db,
                user_id=user_id,
                context_embedding=context_embedding,
                top_k=self.settings.memory_injection_top_k,
            )
            persistent_memories = [
                {
                    "category": item.category,
                    "content": item.content,
                    "relevance_score": item.relevance_score,
                    "emotional_significance": item.emotional_significance,
                    "recurrence_count": item.recurrence_count,
                }
                for item in relevant_entries
            ]

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

        context_window = await self.context_window.build_context_window(
            db,
            user_id=user_id,
            conversation_id=conversation_id,
            user_text=user_text,
        )

        memory_candidates = [
            str(item.get("content", "")).strip()
            for item in persistent_memories
            if str(item.get("content", "")).strip()
        ]
        if not memory_candidates:
            memory_candidates = [item.strip() for item in recent_memories if item.strip()]

        reasoning_output = await self.thinking.reason(
            user_text=user_text,
            conversation_context=context_window.get("conversation") or history_block,
            memory_context=memory_candidates,
            emotions=emotions,
            habits=habits,
            recall_intent=recall_intent,
            supportive_mode=supportive_mode,
        )

        response_plan = self._plan_response(
            user_text=user_text,
            emotions=emotions,
            habits=habits,
            recall_intent=recall_intent,
            supportive_mode=supportive_mode,
            reasoning_output=reasoning_output,
        )

        final_prompt = self._build_prompt(
            user_text=user_text,
            history_block=history_block,
            cross_conversation_history_block=cross_conversation_history_block,
            similar_messages=similar_messages,
            kb_docs=kb_docs,
            kb_entries=kb_entries,
            emotion_stats=emotion_stats,
            habit_stats=habit_stats,
            time_patterns=time_patterns,
            habit_emotion_links=habit_emotion_links,
            recent_memories=recent_memories,
            persistent_memories=persistent_memories,
            emotions=emotions,
            habits=habits,
            recall_intent=recall_intent,
            supportive_mode=supportive_mode,
            reasoning_output=reasoning_output,
            response_plan=response_plan,
            context_window=context_window,
        )

        # NEW: Run internal pattern analysis before finalizing prompt
        analysis_context = {
            "user_text": user_text,
            "emotions": emotions,
            "habits": habits,
            "emotion_stats": emotion_stats,
            "habit_stats": habit_stats,
            "time_patterns": time_patterns,
            "habit_emotion_links": habit_emotion_links,
            "graph_signals": (
                DataPreprocessor.preprocess_habit_emotion_links(habit_emotion_links)
                + DataPreprocessor.preprocess_time_patterns(time_patterns)
                + DataPreprocessor.preprocess_trend_summaries(emotion_stats, habit_stats)
            ),
        }

        analysis = await self.analysis.analyze_patterns(analysis_context)

        # Fetch conversation to check intervention state
        conversation = await db.execute(select(Conversation).where(Conversation.id == conversation_id))
        conversation = conversation.scalar_one()

        # Decide if intervention should be surfaced
        should_surface = InterventionControl.should_intervene(
            analysis=analysis,
            last_intervention_at=conversation.last_intervention_at,
            message_count_since_last=conversation.message_count_since_last_intervention,
            user_state=None,
        )

        # Inject intervention context if approved
        if should_surface and analysis.primary_pattern:
            intervention_injection = InterventionControl.build_intervention_injection(analysis)
            final_prompt += intervention_injection

        return PreparedGenerationContext(
            conversation_id=conversation_id,
            user_id=user_id,
            user_message_id=user_message.id,
            user_timestamp=now,
            user_text=user_text,
            emotions=emotions,
            habits=habits,
            reasoning_output=reasoning_output,
            response_plan=response_plan,
            response_max_tokens=response_plan.max_tokens,
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
            timestamp=assistant_message.timestamp or datetime.utcnow(),
            emotions=context.emotions,
            habits=context.habits,
            role=MessageRole.ASSISTANT.value,
        )

        # NEW: Update intervention tracking
        conversation = await db.execute(select(Conversation).where(Conversation.id == context.conversation_id))
        conversation = conversation.scalar_one()
        conversation.message_count_since_last_intervention += 1
        db.add(conversation)
        await db.flush()

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
            "You generate concise, meaningful titles for personal reflection conversations.\n\n"
            "Goal:\n"
            "Capture the most distinctive theme (emotion, situation, or struggle), not just a generic feeling.\n\n"
            "Constraints:\n\n"
            "- 1 to 2 words\n"
            "- specific > generic (e.g., \"Exam Stress\" better than \"Stress\")\n"
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
        kb_entries: list[dict[str, Any]],
        emotion_stats: list[dict],
        habit_stats: list[dict],
        time_patterns: list[dict],
        habit_emotion_links: list[dict],
        recent_memories: list[str],
        persistent_memories: list[dict[str, Any]] | None = None,
        emotions: list[dict],
        habits: list[dict],
        recall_intent: bool,
        supportive_mode: bool,
        reasoning_output: ReasoningOutput | None = None,
        response_plan: ResponsePlan | None = None,
        context_window: dict[str, str] | None = None,
    ) -> str:
        response_plan = response_plan or self._plan_response(
            user_text=user_text,
            emotions=emotions,
            habits=habits,
            recall_intent=recall_intent,
            supportive_mode=supportive_mode,
            reasoning_output=reasoning_output,
        )
        memory_block = "\n".join(f"- {summary}" for summary in recent_memories) if recent_memories else "- No saved user memories yet."
        if context_window and context_window.get("memories"):
            memory_block = context_window["memories"]

        persistent_memory_block = self._format_persistent_memories(persistent_memories or [])
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
            "Keep responses calm, non-judgmental, and reflective.\n"
            "Optionally ask one gentle follow-up question if it helps the user reflect.\n"
            if supportive_mode
            else "Respond naturally and directly to the user without scripted therapeutic framing. "
            "Do not require a follow-up question if it does not fit.\n"
        )
        knowledge_context = self._format_knowledge_context(kb_entries)
        if context_window and context_window.get("kb_docs"):
            knowledge_context = context_window["kb_docs"]
        if not knowledge_context:
            knowledge_context = "- No relevant WHO guidance matched this message."

        conversation_block = history_block
        if context_window and context_window.get("conversation"):
            conversation_block = context_window["conversation"]

        response_style_block = self._build_response_style_block(response_plan)
        reasoning_block = self._build_reasoning_block(reasoning_output)
        action_hint = self._action_instruction(reasoning_output)

        return (
            "You are MindPal, a calm and supportive mental health assistant.\n\n"
            "Your role:\n\n"
            "- Listen and respond to what the user is sharing\n"
            "- Only reference patterns or history if the user asks about them or if it directly helps with their current concern\n"
            "- Offer practical suggestions only when they're relevant\n"
            "- Never presume or diagnose\n\n"
            "--- PRIORITY ORDER ---\n"
            "Use information in this order:\n\n"
            "1. Current user message (most important)\n"
            "2. Recent conversation context (if relevant)\n"
            "3. Only reference historical patterns if the user asks or if they're directly applicable\n\n"
            "--- CONTEXT ---\n"
            f"Detected current emotions: {emotions}\n"
            f"Detected habits: {habits}\n\n"
            f"Recent conversation:\n{conversation_block}\n\n"
            f"{cross_history_section}"
            "--- INTERNAL THINKING SUMMARY (DO NOT REVEAL JSON OR INTERNAL LABELS) ---\n\n"
            f"{reasoning_block}\n\n"
            "--- RESPONSE PLAN ---\n\n"
            f"{response_style_block}\n\n"
            "--- RESPONSE STYLE ---\n\n"
            "- Start with a brief, genuine acknowledgment of what they've shared\n"
            "- Avoid sounding scripted or overly therapeutic\n"
            "- Only mention patterns if they're highly relevant or the user asks\n"
            "- Avoid asking follow-up questions unless they're genuinely needed for clarity\n"
            "- Keep it natural and conversational\n\n"
            "--- RULES ---\n\n"
            "- Do NOT presume without being asked\n"
            "- Do NOT make speculative guesses about causes or feelings\n"
            "- Do NOT sound clinical or diagnostic\n"
            "- Do NOT present correlations as facts\n"
            "- If something is unclear, ask one simple clarifying question\n"
            "- Otherwise, just respond naturally to what was shared\n\n"
            "--- LENGTH ---\n"
            f"Target: {response_plan.min_sentences}-{response_plan.max_sentences} sentences (stay brief unless more detail is needed)\n\n"
            f"Current user message:\n{user_text}\n\n"
            f"{response_style}"
            f"{quote_rule}\n"
            f"{action_hint}\n"
            "Focus on being helpful and genuine, not on suggesting connections or patterns unless asked."
        )

    def _plan_response(
        self,
        *,
        user_text: str,
        emotions: list[dict[str, Any]],
        habits: list[dict[str, Any]],
        recall_intent: bool,
        supportive_mode: bool,
        reasoning_output: ReasoningOutput | None = None,
    ) -> ResponsePlan:
        normalized_text = " ".join(user_text.lower().split())
        emotional_signal = any(str(item.get("label", "")).strip().lower() not in {"neutral", ""} for item in emotions)
        habit_signal = bool(habits)
        multi_part_request = "\n" in user_text or len(re.findall(r"\b(and|also|plus|another|both)\b", normalized_text)) >= 2
        direct_question = "?" in normalized_text or normalized_text.startswith(("what", "how", "why", "can you", "could you", "should i"))

        if self._is_small_talk_message(user_text):
            return ResponsePlan(
                label="small_talk",
                min_sentences=1,
                max_sentences=1,
                max_tokens=48,
                acknowledge_user=True,
                ask_follow_up=False,
                use_bullets=False,
                tone="warm, short, and natural",
                focus="keep the reply brief and human",
            )

        if recall_intent:
            plan = ResponsePlan(
                label="history_recall",
                min_sentences=2,
                max_sentences=3,
                max_tokens=140,
                acknowledge_user=True,
                ask_follow_up=False,
                use_bullets=False,
                tone="grounded and precise",
                focus="summarize the relevant history without overexplaining",
            )
            return self._with_reasoning_adjustments(plan, reasoning_output)

        if supportive_mode or emotional_signal:
            plan = ResponsePlan(
                label="supportive_reflection",
                min_sentences=2,
                max_sentences=3,
                max_tokens=160,
                acknowledge_user=True,
                ask_follow_up=False,
                use_bullets=False,
                tone="calm and validating",
                focus="acknowledge what they shared, then respond naturally",
            )
            return self._with_reasoning_adjustments(plan, reasoning_output)

        if multi_part_request or habit_signal:
            plan = ResponsePlan(
                label="structured_explanation",
                min_sentences=2,
                max_sentences=4,
                max_tokens=180,
                acknowledge_user=True,
                ask_follow_up=False,
                use_bullets=True,
                tone="clear and helpful",
                focus="organize the answer into a compact explanation or steps",
            )
            return self._with_reasoning_adjustments(plan, reasoning_output)

        if direct_question:
            plan = ResponsePlan(
                label="concise_answer",
                min_sentences=2,
                max_sentences=3,
                max_tokens=160,
                acknowledge_user=True,
                ask_follow_up=False,
                use_bullets=False,
                tone="direct and conversational",
                focus="answer the question plainly before adding detail",
            )
            return self._with_reasoning_adjustments(plan, reasoning_output)

        plan = ResponsePlan(
            label="general_support",
            min_sentences=1,
            max_sentences=3,
            max_tokens=160,
            acknowledge_user=True,
            ask_follow_up=False,
            use_bullets=False,
            tone="brief, calm, and natural",
            focus="keep the reply short unless the user needs more detail",
        )
        return self._with_reasoning_adjustments(plan, reasoning_output)

    @staticmethod
    def _with_reasoning_adjustments(plan: ResponsePlan, reasoning_output: ReasoningOutput | None) -> ResponsePlan:
        if reasoning_output is None:
            return plan

        if reasoning_output.next_best_action == "ask_question":
            return ResponsePlan(
                label=plan.label,
                min_sentences=plan.min_sentences,
                max_sentences=plan.max_sentences,
                max_tokens=plan.max_tokens,
                acknowledge_user=plan.acknowledge_user,
                ask_follow_up=False,
                use_bullets=False,
                tone=plan.tone,
                focus=reasoning_output.response_focus or plan.focus,
            )

        if reasoning_output.next_best_action == "propose_hypothesis":
            return ResponsePlan(
                label=plan.label,
                min_sentences=plan.min_sentences,
                max_sentences=plan.max_sentences,
                max_tokens=plan.max_tokens,
                acknowledge_user=plan.acknowledge_user,
                ask_follow_up=False,
                use_bullets=False,
                tone=plan.tone,
                focus=reasoning_output.response_focus or plan.focus,
            )

        return plan

    @staticmethod
    def _build_reasoning_block(reasoning_output: ReasoningOutput | None) -> str:
        if reasoning_output is None:
            return "No structured reasoning available. Respond naturally to what the user shared."

        high_confidence_hypotheses = [h for h in reasoning_output.hypotheses if h.confidence >= 0.70]
        
        if reasoning_output.should_reference_memory and high_confidence_hypotheses:
            hypothesis_lines = [
                f"- {item.cause} (confidence={item.confidence:.2f})"
                for item in high_confidence_hypotheses[:1]
            ]
            hypothesis_section = f"High-confidence pattern signal:\n{chr(10).join(hypothesis_lines)}\n"
        elif high_confidence_hypotheses:
            hypothesis_section = f"Possible angle (low context): consider asking about {reasoning_output.missing_information[0] if reasoning_output.missing_information else 'their thoughts'}\n"
        else:
            hypothesis_section = ""

        return (
            f"Emotion inference: {reasoning_output.emotion} (confidence={reasoning_output.emotion_confidence:.2f})\n"
            f"{hypothesis_section}"
            f"Next best action: {reasoning_output.next_best_action}\n"
            f"Response focus: {reasoning_output.response_focus}"
        )

    @staticmethod
    def _action_instruction(reasoning_output: ReasoningOutput | None) -> str:
        if reasoning_output is None:
            return "Just respond naturally to what they shared. Only ask a question if you need clarification."

        if reasoning_output.next_best_action == "ask_question":
            return "If you need clarification before responding, ask one simple, natural question. Otherwise, just respond."
        if reasoning_output.next_best_action == "propose_hypothesis":
            return "Optionally mention one possible angle only if it feels natural and relevant."
        return "Acknowledge what they shared and respond supportively."

    @staticmethod
    def _build_response_style_block(response_plan: ResponsePlan) -> str:
        return (
            f"Plan type: {response_plan.label}\n"
            f"Tone: {response_plan.tone}\n"
            f"Focus: {response_plan.focus}\n"
            f"Start with a brief acknowledgment: {'yes' if response_plan.acknowledge_user else 'no'}\n"
            f"Ask one follow-up question at most: {'yes' if response_plan.ask_follow_up else 'no'}\n"
            f"Use bullets only if they make the answer clearer: {'yes' if response_plan.use_bullets else 'no'}\n"
            f"Aim for {response_plan.min_sentences}-{response_plan.max_sentences} sentences."
        )

    @staticmethod
    def _normalize_assistant_text(assistant_text: str, response_plan: ResponsePlan) -> str:
        compact = " ".join(assistant_text.split()).strip()
        if not compact:
            return ""

        if not response_plan.use_bullets:
            compact = re.sub(r"(?m)^[\s>*-•]+", "", compact)
            compact = compact.replace(" - ", "; ")

        sentences = re.split(r"(?<=[.!?])\s+", compact)
        if len(sentences) > response_plan.max_sentences:
            compact = " ".join(sentences[: response_plan.max_sentences]).strip()

        return compact

    @staticmethod
    def _format_persistent_memories(entries: list[dict[str, Any]]) -> str:
        if not entries:
            return "- No persistent memories matched this message."

        lines: list[str] = []
        seen: set[str] = set()
        for entry in entries:
            content = str(entry.get("content", "")).strip()
            if not content:
                continue
            token = content.lower()
            if token in seen:
                continue
            seen.add(token)
            lines.append(f"- {content}")
            if len(lines) >= 6:
                break

        return "\n".join(lines) if lines else "- No persistent memories matched this message."

    @staticmethod
    def _extract_retrieval_tags(user_text: str, emotions: list[dict[str, Any]], habits: list[dict[str, Any]]) -> list[str]:
        tags: set[str] = set()
        tags.update(str(item.get("label", "")).strip().lower() for item in emotions)
        tags.update(str(item.get("habit", "")).strip().lower() for item in habits)

        lowered = user_text.lower()
        keyword_map = {
            "stress": ["stress", "overwhelmed", "burnout"],
            "anxiety": ["anxious", "panic", "worry"],
            "sleep": ["sleep", "insomnia", "bed", "night"],
            "self-care": ["self care", "self-care", "rest", "recharge"],
            "focus": ["focus", "distracted", "procrastinat"],
            "coping": ["cope", "coping", "grounding"],
        }
        for tag, keywords in keyword_map.items():
            if any(keyword in lowered for keyword in keywords):
                tags.add(tag)

        return [tag for tag in sorted(tags) if tag]

    @staticmethod
    def _needs_crisis_resource(user_text: str, emotions: list[dict[str, Any]]) -> bool:
        distress_labels = {"fear", "sadness", "anxiety"}
        emotion_flag = any(str(item.get("label", "")).strip().lower() in distress_labels for item in emotions)
        lowered = user_text.lower()
        crisis_markers = [
            "self-harm",
            "harm myself",
            "suicide",
            "kill myself",
            "not safe",
            "immediate danger",
            "can't go on",
        ]
        text_flag = any(marker in lowered for marker in crisis_markers)
        return emotion_flag and text_flag

    @staticmethod
    def _format_knowledge_context(entries: list[dict[str, Any]]) -> str:
        lines: list[str] = []
        for idx, entry in enumerate(entries[:5], start=1):
            metadata = entry.get("metadata") if isinstance(entry.get("metadata"), dict) else {}
            title = str(metadata.get("title") or metadata.get("topic") or f"WHO Guidance {idx}")
            category = str(metadata.get("category") or "education")
            tags = str(metadata.get("tags") or "")
            content = str(entry.get("content") or "").strip()
            lines.append(f"{idx}. {title} [{category}] tags={tags}: {content}")
        return "\n".join(lines)

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
    def _build_small_talk_prompt(user_text: str, *, response_plan: ResponsePlan) -> str:
        return (
            "You are MindPal, a warm and natural assistant.\n\n"
            f"User message:\n{user_text}\n\n"
            f"Reply with exactly {response_plan.max_sentences} short sentence. "
            f"Tone: {response_plan.tone}. "
            "Keep it human, relaxed, and slightly varied in tone (not repetitive or robotic). "
            "No follow-up question."
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
