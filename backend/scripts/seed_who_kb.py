from __future__ import annotations

import argparse
import asyncio
import json
import re
from dataclasses import dataclass
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
from typing import Iterable

import httpx

from app.services.vector_service import VectorService

DEFAULT_URLS = [
    "https://www.who.int/news-room/questions-and-answers/item/mental-health-strengthening-our-response",
    "https://www.who.int/news-room/fact-sheets/detail/mental-health-strengthening-our-response",
    "https://www.who.int/health-topics/mental-health",
]

CATEGORY_KEYWORDS = {
    "crisis": ["suicide", "self-harm", "emergency", "immediate danger", "crisis"],
    "coping": ["cope", "coping", "breathing", "grounding", "stress"],
    "habit": ["sleep", "routine", "daily", "habit", "exercise"],
    "emotion": ["anxiety", "sad", "worry", "mood", "emotion"],
}

TAG_KEYWORDS = [
    "stress",
    "anxiety",
    "sleep",
    "self-care",
    "burnout",
    "focus",
    "exercise",
    "coping",
    "crisis",
]

CRISIS_TEXT = (
    "If someone is in immediate danger, contact local emergency services right away. "
    "If you are having thoughts of harming yourself, seek urgent support from a local crisis service or emergency department. "
    "WHO guidance emphasizes immediate safety and contacting trusted local support resources."
)


class _TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._skip_depth = 0
        self._parts: list[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:  # noqa: ANN001
        if tag in {"script", "style", "noscript"}:
            self._skip_depth += 1

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "noscript"} and self._skip_depth > 0:
            self._skip_depth -= 1

    def handle_data(self, data: str) -> None:
        if self._skip_depth > 0:
            return
        text = data.strip()
        if text:
            self._parts.append(text)

    def get_text(self) -> str:
        joined = "\n".join(self._parts)
        cleaned = re.sub(r"\s+", " ", joined)
        return unescape(cleaned).strip()


@dataclass
class KBChunk:
    title: str
    content: str
    category: str
    tags: list[str]
    topic: str
    source_url: str
    source: str
    is_crisis: bool

    def to_dict(self, idx: int) -> dict:
        return {
            "id": f"kb_who_{idx:04d}",
            "title": self.title,
            "content": self.content,
            "text": self.content,
            "category": self.category,
            "topic": self.topic,
            "tags": self.tags,
            "source_url": self.source_url,
            "source": self.source,
            "is_crisis": self.is_crisis,
        }


def _split_sentences(text: str) -> list[str]:
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if s.strip()]


def _word_count(text: str) -> int:
    return len(re.findall(r"\b\w+\b", text))


def _categorize(text: str) -> str:
    lowered = text.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in lowered for keyword in keywords):
            return category
    return "education"


def _extract_tags(text: str) -> list[str]:
    lowered = text.lower()
    matched = [tag for tag in TAG_KEYWORDS if tag in lowered]
    return matched[:4] if matched else ["self-care"]


def _make_title(text: str, category: str, idx: int) -> str:
    first_sentence = _split_sentences(text)[0] if _split_sentences(text) else text
    words = first_sentence.split()[:7]
    if words:
        return " ".join(words)
    return f"WHO {category.title()} Guidance {idx}"


def _chunk_text(text: str, min_words: int = 100, max_words: int = 300) -> list[str]:
    sentences = _split_sentences(text)
    chunks: list[str] = []
    current: list[str] = []
    current_words = 0

    for sentence in sentences:
        sentence_words = _word_count(sentence)
        if sentence_words == 0:
            continue

        if current_words + sentence_words > max_words and current_words >= min_words:
            chunks.append(" ".join(current).strip())
            current = [sentence]
            current_words = sentence_words
            continue

        current.append(sentence)
        current_words += sentence_words

    if current:
        final_chunk = " ".join(current).strip()
        if _word_count(final_chunk) < min_words and chunks:
            chunks[-1] = (chunks[-1] + " " + final_chunk).strip()
        else:
            chunks.append(final_chunk)

    return [chunk for chunk in chunks if min_words <= _word_count(chunk) <= max_words]


async def _fetch_text(url: str) -> str:
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        response = await client.get(url)
        response.raise_for_status()
        parser = _TextExtractor()
        parser.feed(response.text)
        return parser.get_text()


def _build_chunks(url: str, text: str) -> list[KBChunk]:
    built: list[KBChunk] = []
    for idx, chunk in enumerate(_chunk_text(text), start=1):
        category = _categorize(chunk)
        built.append(
            KBChunk(
                title=_make_title(chunk, category, idx),
                content=chunk,
                category=category,
                tags=_extract_tags(chunk),
                topic=f"who_{category}",
                source_url=url,
                source="who",
                is_crisis=(category == "crisis"),
            )
        )
    return built


def _append_crisis_entry(chunks: list[KBChunk]) -> None:
    chunks.append(
        KBChunk(
            title="WHO Crisis Referral Guidance",
            content=CRISIS_TEXT,
            category="crisis",
            tags=["crisis", "safety", "support"],
            topic="who_crisis",
            source_url="https://www.who.int/health-topics/mental-health",
            source="who",
            is_crisis=True,
        )
    )


def _write_output(path: Path, chunks: Iterable[KBChunk]) -> list[dict]:
    serialized: list[dict] = [chunk.to_dict(idx) for idx, chunk in enumerate(chunks, start=1)]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(serialized, indent=2), encoding="utf-8")
    return serialized


async def _upsert(entries: list[dict]) -> None:
    vector_service = VectorService()
    for entry in entries:
        await vector_service.upsert_knowledge_doc(
            doc_id=entry["id"],
            text=entry["text"],
            topic=entry["topic"],
            title=entry["title"],
            category=entry["category"],
            tags=entry["tags"],
            is_crisis=bool(entry.get("is_crisis", False)),
            source_url=entry.get("source_url"),
            source=entry.get("source", "who"),
        )


async def _run(urls: list[str], output_path: Path, ingest: bool) -> None:
    chunks: list[KBChunk] = []
    for url in urls:
        text = await _fetch_text(url)
        chunks.extend(_build_chunks(url, text))

    _append_crisis_entry(chunks)
    entries = _write_output(output_path, chunks)
    print(f"Wrote {len(entries)} WHO KB entries to {output_path}")

    if ingest:
        await _upsert(entries)
        print("Upserted WHO KB entries into Chroma")


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch, chunk, and seed WHO mental well-being resources")
    parser.add_argument("--url", action="append", dest="urls", help="WHO URL to ingest. Can be repeated.")
    parser.add_argument(
        "--output",
        default=str(Path(__file__).resolve().parents[1] / "app" / "rag" / "who_kb_seed.json"),
        help="Output JSON file path",
    )
    parser.add_argument("--ingest", action="store_true", help="Also upsert generated chunks into Chroma")
    args = parser.parse_args()

    urls = args.urls or DEFAULT_URLS
    asyncio.run(_run(urls=urls, output_path=Path(args.output), ingest=args.ingest))


if __name__ == "__main__":
    main()
