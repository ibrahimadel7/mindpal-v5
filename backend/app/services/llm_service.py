import asyncio
import hashlib
import json
import logging
from collections.abc import AsyncGenerator
from typing import Any

import httpx

from app.config import get_settings

logger = logging.getLogger(__name__)


class LLMService:
    """Groq LLM service for chat, extraction, and embeddings."""

    def __init__(self) -> None:
        self.settings = get_settings()
        self.base_url = "https://api.groq.com/openai/v1"

    def _headers(self) -> dict[str, str]:
        if not self.settings.groq_api_key:
            raise RuntimeError("GROQ_API_KEY is not configured")
        return {
            "Authorization": f"Bearer {self.settings.groq_api_key}",
            "Content-Type": "application/json",
        }

    async def _request_with_retries(self, method: str, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        headers = self._headers()

        last_err: Exception | None = None
        for attempt in range(1, self.settings.llm_max_retries + 1):
            try:
                async with httpx.AsyncClient(timeout=self.settings.llm_timeout_seconds) as client:
                    response = await client.request(method, f"{self.base_url}{path}", headers=headers, json=payload)
                    response.raise_for_status()
                    return response.json()
            except Exception as exc:  # noqa: BLE001
                last_err = exc
                logger.warning("Groq request failed on attempt %s/%s: %s", attempt, self.settings.llm_max_retries, exc)
                if attempt < self.settings.llm_max_retries:
                    await asyncio.sleep(2 ** (attempt - 1))

        assert last_err is not None
        raise last_err

    async def generate_chat(
        self,
        prompt: str,
        *,
        temperature: float | None = None,
        max_tokens: int | None = None,
    ) -> str:
        payload = {
            "model": self.settings.groq_model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": self.settings.llm_temperature if temperature is None else temperature,
            "max_tokens": self.settings.llm_max_tokens if max_tokens is None else max_tokens,
        }
        data = await self._request_with_retries("POST", "/chat/completions", payload)
        return data["choices"][0]["message"]["content"].strip()

    async def stream_chat_tokens(
        self,
        prompt: str,
        *,
        temperature: float | None = None,
        max_tokens: int | None = None,
    ) -> AsyncGenerator[str, None]:
        """Yield assistant text deltas from Groq's OpenAI-compatible streaming API.

        Streaming improves perceived latency because the UI can render tokens immediately
        rather than waiting for a full completion payload.
        """
        payload = {
            "model": self.settings.groq_model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": self.settings.llm_temperature if temperature is None else temperature,
            "max_tokens": self.settings.llm_max_tokens if max_tokens is None else max_tokens,
            "stream": True,
        }

        headers = self._headers()
        timeout = httpx.Timeout(self.settings.llm_timeout_seconds, read=self.settings.llm_timeout_seconds)

        last_err: Exception | None = None
        for attempt in range(1, self.settings.llm_max_retries + 1):
            try:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    async with client.stream(
                        "POST",
                        f"{self.base_url}/chat/completions",
                        headers=headers,
                        json=payload,
                    ) as response:
                        response.raise_for_status()
                        async for line in response.aiter_lines():
                            if not line or not line.startswith("data:"):
                                continue

                            data = line[len("data:") :].strip()
                            if data == "[DONE]":
                                return

                            try:
                                parsed = json.loads(data)
                            except json.JSONDecodeError:
                                logger.debug("Skipping non-JSON stream frame: %s", data)
                                continue

                            for choice in parsed.get("choices", []):
                                delta = choice.get("delta", {})
                                token = delta.get("content")
                                if token:
                                    yield token
                return
            except Exception as exc:  # noqa: BLE001
                last_err = exc
                logger.warning(
                    "Groq streaming request failed on attempt %s/%s: %s",
                    attempt,
                    self.settings.llm_max_retries,
                    exc,
                )
                if attempt < self.settings.llm_max_retries:
                    await asyncio.sleep(2 ** (attempt - 1))

        assert last_err is not None
        raise last_err

    async def generate_structured_json(
        self,
        system_prompt: str,
        user_prompt: str,
        *,
        temperature: float = 0.0,
        max_tokens: int = 400,
    ) -> dict[str, Any]:
        payload = {
            "model": self.settings.groq_model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "response_format": {"type": "json_object"},
        }
        data = await self._request_with_retries("POST", "/chat/completions", payload)
        raw = data["choices"][0]["message"]["content"].strip()
        try:
            return json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError(f"LLM returned invalid JSON: {raw}") from exc

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        """Generate deterministic embeddings using SHA-256 hash-based method.
        
        Note: Using local embeddings instead of external API for cost efficiency.
        """
        return [self._fallback_embedding(text) for text in texts]

    @staticmethod
    def _fallback_embedding(text: str, dims: int = 256) -> list[float]:
        """Generate deterministic pseudo-embeddings when provider embeddings are unavailable."""
        values: list[float] = []
        seed = text.encode("utf-8")
        counter = 0
        while len(values) < dims:
            digest = hashlib.sha256(seed + str(counter).encode("utf-8")).digest()
            values.extend([((byte / 255.0) * 2.0) - 1.0 for byte in digest])
            counter += 1
        return values[:dims]
