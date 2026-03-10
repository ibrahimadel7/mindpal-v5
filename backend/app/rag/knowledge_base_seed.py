from app.services.vector_service import VectorService

KB_DOCS = [
    {
        "id": "kb_coping_box_breathing",
        "topic": "coping_strategies",
        "text": "Box breathing can reduce acute stress: inhale 4 seconds, hold 4, exhale 4, hold 4, repeat for 2-5 minutes.",
    },
    {
        "id": "kb_cbt_reframe",
        "topic": "cbt_techniques",
        "text": "CBT thought reframing: identify automatic thought, evaluate evidence, then replace with a balanced thought.",
    },
    {
        "id": "kb_emotion_regulation",
        "topic": "emotional_regulation",
        "text": "Name the emotion, validate it, then pick one grounding action such as breathing, stretching, or journaling.",
    },
    {
        "id": "kb_productivity_pomodoro",
        "topic": "productivity_tips",
        "text": "Use the Pomodoro method: 25 minutes focused work and 5 minutes break; after four cycles, take a longer break.",
    },
    {
        "id": "kb_habit_sleep_hygiene",
        "topic": "habit_improvement",
        "text": "Sleep hygiene: fixed bedtime, reduce screens 60 minutes before bed, and avoid caffeine late in the day.",
    },
]


async def seed_knowledge_base() -> None:
    """Idempotently ensure KB documents are in the vector store."""
    vector_service = VectorService()
    for item in KB_DOCS:
        await vector_service.upsert_knowledge_doc(doc_id=item["id"], text=item["text"], topic=item["topic"])
