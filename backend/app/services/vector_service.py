from __future__ import annotations

import asyncio
from datetime import datetime
from typing import Any

import chromadb
from chromadb.api.models.Collection import Collection

from app.config import get_settings
from app.services.llm_service import LLMService


class VectorService:
    """Chroma-backed vector retrieval for messages and knowledge docs."""

    def __init__(self, llm_service: LLMService | None = None) -> None:
        self.settings = get_settings()
        self.llm = llm_service or LLMService()
        self.client = chromadb.PersistentClient(path=self.settings.chroma_persist_dir)
        self.messages_collection: Collection = self.client.get_or_create_collection(
            self.settings.chroma_messages_collection
        )
        self.kb_collection: Collection = self.client.get_or_create_collection(self.settings.chroma_kb_collection)
        self.memory_collection: Collection = self.client.get_or_create_collection(self.settings.chroma_memory_collection)

    async def upsert_message_embedding(
        self,
        *,
        vector_id: str,
        content: str,
        user_id: int,
        conversation_id: int,
        message_id: int,
        timestamp: datetime,
        emotions: list[dict[str, Any]] | None,
        habits: list[dict[str, Any]] | None,
        role: str,
    ) -> None:
        embeddings = await self.llm.embed_texts([content])
        metadata = {
            "user_id": str(user_id),
            "conversation_id": str(conversation_id),
            "message_id": str(message_id),
            "timestamp": timestamp.isoformat(),
            "emotions": ",".join([e.get("label", "") for e in (emotions or [])]),
            "habits": ",".join([h.get("habit", "") for h in (habits or [])]),
            "role": role,
            "source": "chat",
        }

        await asyncio.to_thread(
            self.messages_collection.upsert,
            ids=[vector_id],
            documents=[content],
            embeddings=embeddings,
            metadatas=[metadata],
        )

    @staticmethod
    def _normalize_tags(tags: list[str] | None) -> str:
        if not tags:
            return ""
        clean: list[str] = []
        seen: set[str] = set()
        for tag in tags:
            token = str(tag).strip().lower()
            if not token or token in seen:
                continue
            seen.add(token)
            clean.append(token)
        return ",".join(clean)

    @staticmethod
    def _split_tags(value: str | None) -> list[str]:
        if not value:
            return []
        return [item.strip().lower() for item in str(value).split(",") if item.strip()]

    async def upsert_knowledge_doc(
        self,
        *,
        doc_id: str,
        text: str,
        topic: str,
        title: str | None = None,
        category: str | None = None,
        tags: list[str] | None = None,
        is_crisis: bool = False,
        source_url: str | None = None,
        source: str = "knowledge_base",
    ) -> None:
        embeddings = await self.llm.embed_texts([text])
        metadata = {
            "topic": topic,
            "source": source,
            "title": title or topic,
            "category": category or "education",
            "tags": self._normalize_tags(tags),
            "is_crisis": bool(is_crisis),
            "source_url": source_url or "",
        }
        await asyncio.to_thread(
            self.kb_collection.upsert,
            ids=[doc_id],
            documents=[text],
            embeddings=embeddings,
            metadatas=[metadata],
        )

    async def search_similar_messages(
        self,
        query: str,
        top_k: int,
        *,
        user_id: int,
        conversation_id: int | None = None,
    ) -> list[str]:
        """Retrieve semantically similar chat messages scoped to one user.

        Optional conversation scoping can be applied for strictly local recall.
        """
        embeddings = await self.llm.embed_texts([query])
        where_filter: dict[str, Any] = {"user_id": str(user_id)}
        if conversation_id is not None:
            where_filter = {
                "$and": [
                    {"user_id": str(user_id)},
                    {"conversation_id": str(conversation_id)},
                ]
            }

        result = await asyncio.to_thread(
            self.messages_collection.query,
            query_embeddings=embeddings,
            n_results=top_k,
            where=where_filter,
        )
        return result.get("documents", [[]])[0]

    async def search_knowledge(self, query: str, top_k: int) -> list[str]:
        embeddings = await self.llm.embed_texts([query])
        result = await asyncio.to_thread(self.kb_collection.query, query_embeddings=embeddings, n_results=top_k)
        return result.get("documents", [[]])[0]

    async def upsert_memory_embedding(
        self,
        *,
        vector_id: str,
        content: str,
        user_id: int,
        entry_id: int,
        category: str,
        is_active: bool,
        embedding: list[float] | None = None,
    ) -> None:
        effective_embedding = embedding or (await self.llm.embed_texts([content]))[0]
        metadata = {
            "user_id": str(user_id),
            "entry_id": str(entry_id),
            "category": category,
            "is_active": bool(is_active),
            "source": "memory",
        }
        await asyncio.to_thread(
            self.memory_collection.upsert,
            ids=[vector_id],
            documents=[content],
            embeddings=[effective_embedding],
            metadatas=[metadata],
        )

    async def delete_memory_embedding(self, *, vector_id: str) -> None:
        await asyncio.to_thread(self.memory_collection.delete, ids=[vector_id])

    async def search_memory_entries(
        self,
        *,
        context_embedding: list[float],
        top_k: int,
        user_id: int,
    ) -> list[dict[str, Any]]:
        result = await asyncio.to_thread(
            self.memory_collection.query,
            query_embeddings=[context_embedding],
            n_results=top_k,
            where={
                "$and": [
                    {"user_id": str(user_id)},
                    {"is_active": True},
                ]
            },
            include=["distances", "metadatas", "documents"],
        )

        metadatas = result.get("metadatas", [[]])[0]
        distances = result.get("distances", [[]])[0]
        documents = result.get("documents", [[]])[0]
        ids = result.get("ids", [[]])[0]

        items: list[dict[str, Any]] = []
        for idx, metadata in enumerate(metadatas):
            if not isinstance(metadata, dict):
                continue
            entry_id = int(metadata.get("entry_id", 0))
            if entry_id <= 0:
                continue
            items.append(
                {
                    "vector_id": ids[idx] if idx < len(ids) else "",
                    "entry_id": entry_id,
                    "distance": float(distances[idx]) if idx < len(distances) else 1.0,
                    "content": documents[idx] if idx < len(documents) else "",
                    "category": str(metadata.get("category", "")),
                }
            )
        return items

    async def search_knowledge_entries(
        self,
        query: str,
        top_k: int,
        *,
        tags: list[str] | None = None,
        include_crisis: bool = False,
    ) -> list[dict[str, Any]]:
        """Retrieve KB entries with metadata and optional tag-aware reranking."""
        embeddings = await self.llm.embed_texts([query])
        candidate_count = max(top_k * 4, top_k)
        result = await asyncio.to_thread(
            self.kb_collection.query,
            query_embeddings=embeddings,
            n_results=candidate_count,
            include=["documents", "metadatas", "distances"],
        )

        documents = result.get("documents", [[]])[0]
        metadatas = result.get("metadatas", [[]])[0]
        distances = result.get("distances", [[]])[0]
        normalized_tags = {str(tag).strip().lower() for tag in (tags or []) if str(tag).strip()}

        candidates: list[dict[str, Any]] = []
        for idx, document in enumerate(documents):
            metadata = metadatas[idx] if idx < len(metadatas) and isinstance(metadatas[idx], dict) else {}
            if not include_crisis and bool(metadata.get("is_crisis", False)):
                continue

            entry_tags = set(self._split_tags(metadata.get("tags")))
            overlap = len(normalized_tags.intersection(entry_tags))
            distance = distances[idx] if idx < len(distances) else 0.0
            candidates.append(
                {
                    "id": result.get("ids", [[]])[0][idx] if idx < len(result.get("ids", [[]])[0]) else "",
                    "content": document,
                    "metadata": metadata,
                    "distance": float(distance) if isinstance(distance, (int, float)) else 0.0,
                    "tag_overlap": overlap,
                }
            )

        candidates.sort(key=lambda item: (-item["tag_overlap"], item["distance"]))
        deduped: list[dict[str, Any]] = []
        seen_titles: set[str] = set()
        for item in candidates:
            title = str(item["metadata"].get("title") or "").strip().lower()
            if title and title in seen_titles:
                continue
            if title:
                seen_titles.add(title)
            deduped.append(item)
            if len(deduped) >= top_k:
                break
        return deduped
