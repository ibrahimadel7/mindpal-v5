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

    async def upsert_message_embedding(
        self,
        *,
        vector_id: str,
        content: str,
        conversation_id: int,
        message_id: int,
        timestamp: datetime,
        emotions: list[dict[str, Any]] | None,
        habits: list[dict[str, Any]] | None,
        role: str,
    ) -> None:
        embeddings = await self.llm.embed_texts([content])
        metadata = {
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

    async def upsert_knowledge_doc(self, doc_id: str, text: str, topic: str) -> None:
        embeddings = await self.llm.embed_texts([text])
        await asyncio.to_thread(
            self.kb_collection.upsert,
            ids=[doc_id],
            documents=[text],
            embeddings=embeddings,
            metadatas=[{"topic": topic, "source": "knowledge_base"}],
        )

    async def search_similar_messages(self, query: str, top_k: int) -> list[str]:
        embeddings = await self.llm.embed_texts([query])
        result = await asyncio.to_thread(
            self.messages_collection.query,
            query_embeddings=embeddings,
            n_results=top_k,
        )
        return result.get("documents", [[]])[0]

    async def search_knowledge(self, query: str, top_k: int) -> list[str]:
        embeddings = await self.llm.embed_texts([query])
        result = await asyncio.to_thread(self.kb_collection.query, query_embeddings=embeddings, n_results=top_k)
        return result.get("documents", [[]])[0]
