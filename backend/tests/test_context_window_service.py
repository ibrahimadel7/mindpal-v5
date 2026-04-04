from __future__ import annotations

from types import SimpleNamespace
import unittest
from unittest.mock import patch

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.database.base import Base
from app.models.conversation import Conversation
from app.models.message import Message, MessageRole
from app.models.user import User
from app.services.context_window_service import ContextWindowService, classify_message_type, estimate_tokens


class _FakeLLM:
    def __init__(self, *, fail_summary: bool = False) -> None:
        self.fail_summary = fail_summary

    async def generate_chat(self, prompt: str, *, temperature: float | None = None, max_tokens: int | None = None) -> str:
        if self.fail_summary:
            raise RuntimeError("summary failed")
        return "The user has recurring stress and is trying to improve routines."

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        return [[0.1, 0.2, 0.3] for _ in texts]


class _FakeChatMemoryService:
    def __init__(self, values: list[str]) -> None:
        self.values = values

    async def get_recent_memories(self, db: AsyncSession, *, user_id: int, limit: int | None = None) -> list[str]:
        if limit is None:
            return list(self.values)
        return list(self.values[:limit])


class _FakeMemoryService:
    def __init__(self, values: list[str]) -> None:
        self.values = values

    async def query_relevant_memories(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        context_embedding: list[float],
        top_k: int,
    ) -> list[SimpleNamespace]:
        return [SimpleNamespace(content=value) for value in self.values[:top_k]]


class _FakeVectorService:
    def __init__(self, docs: list[str], *, fail_if_called: bool = False) -> None:
        self.docs = docs
        self.fail_if_called = fail_if_called

    async def search_knowledge_entries(
        self,
        query: str,
        top_k: int,
        *,
        tags: list[str] | None = None,
        include_crisis: bool = False,
    ) -> list[dict[str, str]]:
        if self.fail_if_called:
            raise AssertionError("KB retrieval should not be called for casual messages")
        return [{"content": doc} for doc in self.docs[:top_k]]


class ContextWindowServiceTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self.engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        self.session_factory = sessionmaker(self.engine, class_=AsyncSession, expire_on_commit=False)

    async def asyncTearDown(self) -> None:
        await self.engine.dispose()

    async def _seed_conversation(self, session: AsyncSession, *, user_id: int = 1) -> int:
        session.add(User(id=user_id))
        await session.flush()

        conversation = Conversation(user_id=user_id, title="Ctx Test", is_closed=False)
        session.add(conversation)
        await session.flush()

        session.add(Message(conversation_id=conversation.id, role=MessageRole.USER, content="I feel tense lately."))
        session.add(Message(conversation_id=conversation.id, role=MessageRole.ASSISTANT, content="Thanks for sharing that."))
        await session.flush()
        return int(conversation.id)

    async def test_build_context_window_skips_kb_for_casual_message(self) -> None:
        session = self.session_factory()
        conversation_id = await self._seed_conversation(session)

        service = ContextWindowService(
            llm_service=_FakeLLM(),
            chat_memory_service=_FakeChatMemoryService(["You are working on calmer evenings."]),
            memory_service=_FakeMemoryService(["You often feel stress around deadlines."]),
            vector_service=_FakeVectorService(["Breathing can lower stress quickly."], fail_if_called=True),
        )

        result = await service.build_context_window(session, 1, conversation_id, "hi")

        self.assertIn("User:", result["conversation"])
        self.assertIn("-", result["memories"])
        self.assertEqual(result["kb_docs"], "")
        await session.close()

    async def test_build_context_window_trims_kb_before_memories(self) -> None:
        session = self.session_factory()
        conversation_id = await self._seed_conversation(session)

        long_memory = "I keep trying to improve my habits while handling stress and routines. " * 16
        long_kb = "Try 4 second inhale and 6 second exhale during breaks to reduce stress. " * 16
        memories = [f"memory-{idx} {long_memory}" for idx in range(5)]
        kb_docs = [f"doc-{idx} {long_kb}" for idx in range(5)]
        service = ContextWindowService(
            llm_service=_FakeLLM(),
            chat_memory_service=_FakeChatMemoryService(memories),
            memory_service=_FakeMemoryService(memories),
            vector_service=_FakeVectorService(kb_docs),
        )

        with patch("app.services.context_window_service.AVAILABLE_CONTEXT_TOKENS", 430):
            result = await service.build_context_window(session, 1, conversation_id, "How can I reduce stress during study?")

        memory_lines = [line for line in result["memories"].splitlines() if line.strip()]
        kb_lines = [line for line in result["kb_docs"].splitlines() if line.strip()]

        self.assertEqual(len(memory_lines), 5)
        self.assertLess(len(kb_lines), 5)
        await session.close()

    async def test_summarize_messages_fallback_when_llm_fails(self) -> None:
        service = ContextWindowService(
            llm_service=_FakeLLM(fail_summary=True),
            chat_memory_service=_FakeChatMemoryService([]),
            memory_service=_FakeMemoryService([]),
            vector_service=_FakeVectorService([]),
        )

        messages = [
            Message(conversation_id=1, role=MessageRole.USER, content="I feel exhausted and keep overthinking."),
            Message(conversation_id=1, role=MessageRole.USER, content="I also want better sleep consistency."),
        ]

        summary = await service.summarize_messages(messages)
        self.assertIn("Earlier", summary)


class ContextWindowUtilitiesTests(unittest.TestCase):
    def test_estimate_tokens(self) -> None:
        self.assertEqual(estimate_tokens(""), 0)
        self.assertEqual(estimate_tokens("abcd"), 1)
        self.assertEqual(estimate_tokens("abcdefgh"), 2)

    def test_classify_message_type(self) -> None:
        self.assertEqual(classify_message_type("hi"), "casual")
        self.assertEqual(classify_message_type("I feel overwhelmed and anxious."), "emotional")
        self.assertEqual(classify_message_type("What is a grounding technique?"), "informational")


if __name__ == "__main__":
    unittest.main()
