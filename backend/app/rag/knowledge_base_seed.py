import json
from pathlib import Path

from app.services.vector_service import VectorService

KB_DOCS = [
    {
        "id": "kb_coping_box_breathing",
        "topic": "coping_strategies",
        "title": "Box Breathing for Acute Stress",
        "category": "coping",
        "tags": ["stress", "breathing", "grounding"],
        "text": "Box breathing can reduce acute stress: inhale 4 seconds, hold 4, exhale 4, hold 4, repeat for 2-5 minutes.",
    },
    {
        "id": "kb_cbt_reframe",
        "topic": "cbt_techniques",
        "title": "Reframing Automatic Thoughts",
        "category": "education",
        "tags": ["thinking", "stress", "reframing"],
        "text": "CBT thought reframing: identify automatic thought, evaluate evidence, then replace with a balanced thought.",
    },
    {
        "id": "kb_emotion_regulation",
        "topic": "emotional_regulation",
        "title": "Quick Emotion Regulation Sequence",
        "category": "emotion",
        "tags": ["emotion", "grounding", "self-care"],
        "text": "Name the emotion, validate it, then pick one grounding action such as breathing, stretching, or journaling.",
    },
    {
        "id": "kb_productivity_pomodoro",
        "topic": "productivity_tips",
        "title": "Pomodoro Focus Reset",
        "category": "habit",
        "tags": ["focus", "routine", "productivity"],
        "text": "Use the Pomodoro method: 25 minutes focused work and 5 minutes break; after four cycles, take a longer break.",
    },
    {
        "id": "kb_habit_sleep_hygiene",
        "topic": "habit_improvement",
        "title": "Sleep Hygiene Basics",
        "category": "habit",
        "tags": ["sleep", "routine", "self-care"],
        "text": "Sleep hygiene: fixed bedtime, reduce screens 60 minutes before bed, and avoid caffeine late in the day.",
    },
]


def _load_who_seed_entries() -> list[dict]:
    """Load optional WHO chunks produced by the ingestion script."""
    seed_path = Path(__file__).with_name("who_kb_seed.json")
    if not seed_path.exists():
        return []
    with seed_path.open("r", encoding="utf-8") as file:
        payload = json.load(file)
    if not isinstance(payload, list):
        return []
    return [item for item in payload if isinstance(item, dict)]


async def seed_knowledge_base() -> None:
    """Idempotently ensure KB documents are in the vector store."""
    vector_service = VectorService()
    all_docs = [*KB_DOCS, *_load_who_seed_entries()]
    for item in all_docs:
        await vector_service.upsert_knowledge_doc(
            doc_id=item["id"],
            text=item["text"],
            topic=item.get("topic", item.get("category", "wellbeing")),
            title=item.get("title"),
            category=item.get("category"),
            tags=item.get("tags") if isinstance(item.get("tags"), list) else None,
            is_crisis=bool(item.get("is_crisis", False)),
            source_url=item.get("source_url"),
            source=item.get("source", "knowledge_base"),
        )
