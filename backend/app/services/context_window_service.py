from __future__ import annotations

import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.message import Message, MessageRole
from app.database.session import SessionLocal
from app.services.chat_memory_service import ChatMemoryService
from app.services.llm_service import LLMService
from app.services.memory_service import MemoryService
from app.services.vector_service import VectorService

logger = logging.getLogger(__name__)

MAX_TOTAL_TOKENS = 3000
RESERVED_FOR_RESPONSE = 500
AVAILABLE_CONTEXT_TOKENS = MAX_TOTAL_TOKENS - RESERVED_FOR_RESPONSE
DEFAULT_RECENT_MESSAGES = 12
DEFAULT_VERBATIM_RECENT = 6


class ContextWindowService:
    """Builds token-aware context blocks from conversation, memory, and KB retrieval."""

    def __init__(
        self,
        llm_service: LLMService | None = None,
        chat_memory_service: ChatMemoryService | None = None,
        memory_service: MemoryService | None = None,
        vector_service: VectorService | None = None,
    ) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.vector = vector_service or VectorService(self.llm)
        self.chat_memory = chat_memory_service or ChatMemoryService(self.llm)
        self.persistent_memory = memory_service or MemoryService(self.llm, self.vector)
        self._kb_cache: dict[tuple[str, int], list[str]] = {}

    async def build_context_window(
        self,
        db: AsyncSession,
        user_id: int,
        conversation_id: int,
        user_text: str,
    ) -> dict[str, str]:
        """Return compact context sections ready for prompt injection."""
        try:
            message_type = classify_message_type(user_text)
            recent_rows = (
                await db.execute(
                    select(Message)
                    .where(Message.conversation_id == conversation_id)
                    .order_by(Message.timestamp.desc(), Message.id.desc())
                    .limit(DEFAULT_RECENT_MESSAGES)
                )
            ).scalars().all()
            recent_messages = list(reversed(recent_rows))

            conversation_block = self._format_messages(recent_messages)
            conversation_tokens = estimate_tokens(conversation_block)

            needs_compaction = conversation_tokens > int(AVAILABLE_CONTEXT_TOKENS * 0.60)
            if needs_compaction and len(recent_messages) > DEFAULT_VERBATIM_RECENT:
                older_messages = recent_messages[:-DEFAULT_VERBATIM_RECENT]
                recent_verbatim = recent_messages[-DEFAULT_VERBATIM_RECENT:]
                older_summary = await self.summarize_messages(older_messages)
                recent_block = self._format_messages(recent_verbatim)
                conversation_block = (
                    f"Earlier summary: {older_summary}\n\nRecent messages:\n{recent_block}" if older_summary else recent_block
                )

            memory_top_k = 6 if message_type == "emotional" else 5
            memories = await self.get_relevant_memories(db, user_id=user_id, user_text=user_text, top_k=memory_top_k)

            kb_docs: list[str] = []
            if message_type != "casual":
                kb_top_k = 6 if message_type == "informational" else 5
                kb_docs = await self.get_kb_docs(user_text=user_text, top_k=kb_top_k)

            conversation_lines = [line for line in conversation_block.splitlines() if line.strip()]
            memory_lines = [f"- {line}" for line in memories if line.strip()]
            kb_lines = [f"- {line}" for line in kb_docs if line.strip()]

            conversation_block, memory_lines, kb_lines = await self._apply_token_budget(
                conversation_lines=conversation_lines,
                memory_lines=memory_lines,
                kb_lines=kb_lines,
                user_text=user_text,
            )

            final_context = {
                "conversation": conversation_block,
                "memories": "\n".join(memory_lines),
                "kb_docs": "\n".join(kb_lines),
            }
            logger.debug(
                "Context window built user=%s conv=%s type=%s tokens(conv=%s mem=%s kb=%s)",
                user_id,
                conversation_id,
                message_type,
                estimate_tokens(final_context["conversation"]),
                estimate_tokens(final_context["memories"]),
                estimate_tokens(final_context["kb_docs"]),
            )
            return final_context
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "Context window build failed user=%s conv=%s: %s",
                user_id,
                conversation_id,
                exc,
            )
            return {
                "conversation": "",
                "memories": "",
                "kb_docs": "",
            }

    async def summarize_messages(self, messages: list[Message]) -> str:
        if not messages:
            return ""

        transcript = self._format_messages(messages)
        prompt = (
            "Summarize the earlier part of this chat in 2-3 short lines.\n"
            "Keep only durable user context, emotions, and goals.\n"
            "No markdown bullets. No clinical language.\n\n"
            f"Chat:\n{transcript}\n\n"
            "Summary:"
        )
        try:
            summary = await self.llm.generate_chat(prompt, temperature=0.2, max_tokens=100)
            compact = " ".join(summary.split())
            return compact[:420]
        except Exception as exc:  # noqa: BLE001
            logger.warning("LLM message summarization failed: %s", exc)
            return self._fallback_summarize(messages)

    async def get_relevant_memories(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        user_text: str,
        top_k: int = 5,
    ) -> list[str]:
        candidates: list[str] = []

        recent_memories = await self.chat_memory.get_recent_memories(db, user_id=user_id, limit=top_k)
        candidates.extend(recent_memories)

        if self.settings.memory_injection_enabled:
            try:
                context_embedding = (await self.llm.embed_texts([user_text]))[0]
                persistent = await self.persistent_memory.query_relevant_memories(
                    db,
                    user_id=user_id,
                    context_embedding=context_embedding,
                    top_k=top_k,
                )
                candidates.extend([item.content for item in persistent if item.content.strip()])
            except Exception as exc:  # noqa: BLE001
                logger.warning("Persistent memory retrieval failed for user=%s: %s", user_id, exc)

        deduped: list[str] = []
        seen: set[str] = set()
        for memory in candidates:
            compact = self._compact_line(memory, max_chars=180)
            if not compact:
                continue
            token = compact.lower()
            if token in seen:
                continue
            seen.add(token)
            deduped.append(compact)
            if len(deduped) >= top_k:
                break

        return deduped

    async def get_kb_docs(self, user_text: str, top_k: int = 5) -> list[str]:
        cache_key = (" ".join(user_text.lower().split()), top_k)
        cached = self._kb_cache.get(cache_key)
        if cached is not None:
            return list(cached)

        entries = await self.vector.search_knowledge_entries(user_text, top_k)
        docs: list[str] = []
        seen: set[str] = set()
        for entry in entries:
            content = self._compact_line(str(entry.get("content") or ""), max_chars=180)
            if not content:
                continue
            token = content.lower()
            if token in seen:
                continue
            seen.add(token)
            docs.append(content)
            if len(docs) >= top_k:
                break

        self._kb_cache[cache_key] = list(docs)
        if len(self._kb_cache) > 128:
            oldest = next(iter(self._kb_cache))
            self._kb_cache.pop(oldest, None)
        return docs

    async def _apply_token_budget(
        self,
        *,
        conversation_lines: list[str],
        memory_lines: list[str],
        kb_lines: list[str],
        user_text: str,
    ) -> tuple[str, list[str], list[str]]:
        def total_tokens() -> int:
            return estimate_tokens("\n".join(conversation_lines)) + estimate_tokens("\n".join(memory_lines)) + estimate_tokens(
                "\n".join(kb_lines)
            )

        overage = total_tokens() - AVAILABLE_CONTEXT_TOKENS
        if overage <= 0:
            return "\n".join(conversation_lines), memory_lines, kb_lines

        kb_trimmed = 0
        while kb_lines and total_tokens() > AVAILABLE_CONTEXT_TOKENS:
            kb_lines.pop()
            kb_trimmed += 1

        memory_trimmed = 0
        while memory_lines and total_tokens() > AVAILABLE_CONTEXT_TOKENS:
            memory_lines.pop()
            memory_trimmed += 1

        if total_tokens() > AVAILABLE_CONTEXT_TOKENS and len(conversation_lines) > 2:
            # Re-summarize conversation harder only after kb+memory were reduced.
            compact_target = max(4, len(conversation_lines) // 3)
            conversation_lines = conversation_lines[-compact_target:]
            if total_tokens() > AVAILABLE_CONTEXT_TOKENS:
                summary_text = await self.summarize_messages(
                    [
                        Message(conversation_id=0, role=MessageRole.USER, content=line)
                        for line in conversation_lines
                    ]
                )
                conversation_lines = [f"Conversation summary: {self._compact_line(summary_text, max_chars=260)}"]

        logger.debug(
            "Context trimming applied kb_trimmed=%s memory_trimmed=%s final_tokens=%s user_text_len=%s",
            kb_trimmed,
            memory_trimmed,
            total_tokens(),
            len(user_text),
        )
        return "\n".join(conversation_lines), memory_lines, kb_lines

    @staticmethod
    def _format_messages(messages: list[Message]) -> str:
        lines: list[str] = []
        for message in messages:
            content = str(message.content or "").strip()
            if not content:
                continue
            if message.role == MessageRole.USER:
                role = "User"
            elif message.role == MessageRole.ASSISTANT:
                role = "Assistant"
            else:
                role = str(message.role.value if hasattr(message.role, "value") else message.role).capitalize()
            lines.append(f"{role}: {content}")
        return "\n".join(lines)

    @staticmethod
    def _fallback_summarize(messages: list[Message]) -> str:
        user_lines = [str(item.content).strip() for item in messages if item.role == MessageRole.USER and str(item.content).strip()]
        if not user_lines:
            return "Earlier messages covered related personal context and follow-up requests."

        first = user_lines[0]
        last = user_lines[-1]
        if first == last:
            return f"Earlier, the user shared: {first[:180]}"
        return (
            f"Earlier, the user shared: {first[:140]}. "
            f"Later, they emphasized: {last[:140]}."
        )

    @staticmethod
    def _compact_line(text: str, *, max_chars: int) -> str:
        compact = " ".join(str(text).replace("\n", " ").split())
        if not compact:
            return ""
        if len(compact) <= max_chars:
            return compact
        return compact[: max_chars - 3].rstrip() + "..."


def estimate_tokens(text: str) -> int:
    compact = str(text or "")
    if not compact:
        return 0
    return (len(compact) + 3) // 4


def classify_message_type(user_text: str) -> str:
    lowered = " ".join(user_text.lower().split())
    if not lowered:
        return "casual"

    casual_markers = {
        "hi",
        "hey",
        "hello",
        "thanks",
        "thank you",
        "ok",
        "okay",
        "good morning",
        "good night",
    }
    if lowered in casual_markers or len(lowered) <= 12:
        return "casual"

    emotional_markers = [
        "feel",
        "anxious",
        "stressed",
        "overwhelmed",
        "sad",
        "panic",
        "hopeless",
        "lonely",
        "burnout",
        "can't cope",
    ]
    if any(marker in lowered for marker in emotional_markers):
        return "emotional"

    informational_markers = [
        "what",
        "how",
        "why",
        "explain",
        "tips",
        "technique",
        "strategy",
        "research",
        "evidence",
        "help me understand",
    ]
    if any(marker in lowered for marker in informational_markers):
        return "informational"

    return "informational"


async def build_context_window(user_id: int, conversation_id: int, user_text: str) -> dict[str, str]:
    """Convenience wrapper with the requested signature.

    This helper opens its own async DB session for callers outside the pipeline.
    """
    service = ContextWindowService()
    async with SessionLocal() as db:
        return await service.build_context_window(
            db,
            user_id=user_id,
            conversation_id=conversation_id,
            user_text=user_text,
        )
