from __future__ import annotations

from datetime import datetime

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
        # 1. Save message to SQL database
        user_message = Message(conversation_id=conversation_id, role=MessageRole.USER, content=user_text)
        db.add(user_message)
        await db.flush()

        # 2. Generate embedding and 3. store user message embedding
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

        # 4 and 5. LLM analysis
        emotion_result: EmotionDetectionResult = await self.emotion.detect_emotions(user_text)
        habit_result: HabitDetectionResult = await self.habit.detect_habits(user_text)

        # 6. Store analysis
        analysis = MessageAnalysis(
            message_id=user_message.id,
            emotions_json=emotion_result.model_dump(),
            habits_json=habit_result.model_dump(),
            detected_topics_json={"topics": []},
            time_of_day=str(now.hour),
            day_of_week=now.strftime("%A"),
        )
        db.add(analysis)

        # 7. Update graph relationships
        self.graph.update_relationships(
            user_id=user_id,
            message_id=user_message.id,
            emotions=emotion_result.model_dump()["emotions"],
            habits=habit_result.model_dump()["habits"],
        )

        # 8-10. retrieve similar + kb + insights
        similar_messages = await self.vector.search_similar_messages(user_text, self.settings.retrieval_top_k_messages)
        kb_docs = await self.vector.search_knowledge(user_text, self.settings.retrieval_top_k_kb)
        emotion_stats = await self.analytics.emotion_stats(db, conversation_id=conversation_id)
        habit_stats = await self.analytics.habit_stats(db, conversation_id=conversation_id)
        time_patterns = await self.analytics.time_patterns(db, conversation_id=conversation_id)

        # 11. conversation history
        history_rows = (
            await db.execute(
                select(Message.role, Message.content)
                .where(Message.conversation_id == conversation_id)
                .order_by(Message.timestamp.desc())
                .limit(8)
            )
        ).all()
        history_block = "\n".join([f"{row.role.value}: {row.content}" for row in reversed(history_rows)])

        # 12. Build final prompt
        final_prompt = self._build_prompt(
            user_text=user_text,
            history_block=history_block,
            similar_messages=similar_messages,
            kb_docs=kb_docs,
            emotion_stats=emotion_stats,
            habit_stats=habit_stats,
            time_patterns=time_patterns,
            emotions=emotion_result.model_dump()["emotions"],
            habits=habit_result.model_dump()["habits"],
        )

        # 13. Generate assistant response
        assistant_text = await self.llm.generate_chat(final_prompt)

        # 14. Store assistant response
        assistant_message = Message(
            conversation_id=conversation_id,
            role=MessageRole.ASSISTANT,
            content=assistant_text,
        )
        db.add(assistant_message)
        await db.flush()

        # 15. Store assistant embedding
        await self.vector.upsert_message_embedding(
            vector_id=f"msg-{assistant_message.id}",
            content=assistant_text,
            conversation_id=conversation_id,
            message_id=assistant_message.id,
            timestamp=assistant_message.timestamp or datetime.utcnow(),
            emotions=emotion_result.model_dump()["emotions"],
            habits=habit_result.model_dump()["habits"],
            role=MessageRole.ASSISTANT.value,
        )

        # 16. Return response
        await db.commit()
        return {
            "conversation_id": conversation_id,
            "user_message_id": user_message.id,
            "assistant_message_id": assistant_message.id,
            "response": assistant_text,
            "timestamp": assistant_message.timestamp,
        }

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
            "Generate a personalized response with:\n"
            "1) brief emotional validation\n"
            "2) one actionable coping or habit suggestion\n"
            "3) one optional follow-up question\n"
            "Keep response under 180 words."
        )
