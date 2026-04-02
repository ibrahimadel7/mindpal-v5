# MindPal - Copilot Instructions

A FastAPI-based mental health RAG chatbot combining real-time conversation analysis, emotion tracking, and behavioral insights.

## Build, Test, and Lint Commands

### Backend (Python 3.11+)

**Setup:**
```bash
cd backend
python -m venv ../.venv
source ../.venv/bin/activate  # Windows: ..\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Environment:**
```bash
cp .env.example .env
# Edit .env and set GROQ_API_KEY=gsk_your_actual_key
```

**Run server:**
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Run tests:**
```bash
# From backend/ directory
pytest                                    # Run all tests
pytest tests/test_conversation_title.py   # Run single test file
pytest -v                                 # Verbose output
pytest -k "test_name"                     # Run specific test by name
```

**No linter configured** - Code uses standard Python conventions.

### Frontend (React + TypeScript + Vite)

**Setup:**
```bash
cd frontend
npm install
```

**Run dev server:**
```bash
npm run dev      # Starts on http://localhost:5173
```

**Build:**
```bash
npm run build    # TypeScript compilation + Vite build
```

**Lint:**
```bash
npm run lint     # ESLint with TypeScript support
```

**Preview production build:**
```bash
npm run preview  # Serves built files on http://localhost:4173
```

## Architecture Overview

### Backend Service Layer (backend/app/services/)

MindPal uses a service-oriented architecture with dependency injection via the RAGPipeline orchestrator:

- **LLMService** - Groq API integration for chat completions, structured JSON extraction, and embeddings
- **ChatMemoryService** - Summarizes closed conversations into short-term memories (max 10 per user)
- **VectorService** - Semantic search using Chroma vector DB with dual collections (user messages + knowledge base)
- **GraphService** - Singleton NetworkX graph tracking user-message-emotion-habit relationships (persisted to `mindpal_graph.json`)
- **EmotionService** - LLM-based emotion detection (joy, sadness, anger, fear, anxiety, stress, neutral)
- **HabitService** - LLM-based habit/behavior extraction from messages
- **RecommendationService** - Generates personalized recommendations based on user context

**Pattern:** All services are async-first and use SQLAlchemy AsyncSession.

### Database Models (backend/app/models/)

Core entities with cascade deletes for data consistency:

```
User
├── Conversation (title, is_closed, closed_at)
│   ├── Message (role: user|assistant, content, timestamp)
│   │   └── MessageAnalysis (emotions_json, habits_json, time_of_day, day_of_week)
│   └── UserChatMemory (1:1 summary when conversation closes)
├── RecommendationBatch (category, batch_date, context_summary_json)
│   ├── RecommendationItem (title, rationale, action_payload_json, status)
│   └── RecommendationInteraction (event_type, created_at)
└── UserHabit (name, category, is_active, archived_at)
    └── UserHabitCheck (daily completion tracking)
```

**Storage:** SQLite + SQLAlchemy ORM with AsyncIO support (`sqlite+aiosqlite://`)

### RAG Pipeline Flow (backend/app/rag/)

The `RAGPipeline.run()` and `RAGPipeline.run_stream()` methods orchestrate:

1. **Save user message** → Create Message + MessageAnalysis + vector embedding
2. **Analyze content** → Extract emotions/habits via LLM
3. **Classify intent** → Small talk vs history recall vs distress support
4. **Build context** → Retrieve similar past messages (top 5), KB docs (top 3), recent chat memories (last 10)
5. **Generate response** → Stream or non-stream with error recovery
6. **Finalize** → Save assistant message, update vectors, update graph, auto-generate conversation title

**Knowledge base:** 5 hardcoded documents on coping strategies, CBT, emotion regulation, productivity, sleep hygiene. Seeded to Chroma on startup.

**Streaming:** Server-Sent Events (SSE) with event types: `message_start`, `token`, `message_end`, `error`. Graceful fallback to full completion on stream failure.

### Frontend Architecture (frontend/src/)

**State management:** Context-based store pattern (`AppStateContext` + `AppStateStore`)
- Zustand-like interface with methods like `selectConversation()`, `sendMessage()`, `fetchInsights()`
- Hydrates messages on-demand when conversation selected
- Handles streaming chat via SSE

**Routes:**
- `/chat` - Main chat interface with optional insights rail
- `/insights` - Full dashboard with trends, correlations, metrics
- `/recommendations` - Recommendation history and daily checklist

**API client:** Centralized Axios instance in `services/api.ts` with typed responses

### Analytics System (backend/app/analytics/)

**TimePatternAnalytics** - SQL-based aggregations for:
- `emotion_stats()` / `habit_stats()` - Most common labels
- `time_patterns()` - Hour-of-day peaks for emotions/habits
- `daily_emotion_trends()` / `daily_habit_trends()` - Time series data
- `habit_emotion_links()` - Co-occurrence correlations
- `overview_metrics()` - Snapshot stats (total messages, active days, dominant patterns)

**GraphService** - NetworkX graph persisted to JSON:
- Nodes: `user:{id}`, `message:{id}`, `emotion:{label}`, `habit:{name}`
- Edges: `authored`, `expresses` (message→emotion), `mentions` (message→habit), `correlates` (emotion↔habit)
- Method: `top_emotion_habit_correlations()` returns weighted edge list

## Key Conventions

### Error Handling

**LLM service errors:**
- Missing/invalid `GROQ_API_KEY` raises `LLMServiceError`
- Services fall back to local heuristics when LLM unavailable
- API endpoints return HTTP 502/503 for upstream provider issues

**Streaming errors:**
- SSE `error` event includes `error_code` and `retryable` flag
- Frontend shows partial response + error banner on stream failure
- Timeout vs connection errors distinguished for retry logic

**Validation:**
- Pydantic schemas enforce field types, length limits (e.g., message max 5000 chars)
- 404 for resource not found, 409 for state conflicts (e.g., closed conversation)

### Database Patterns

**Cascade deletes:** All relationships use `cascade="all, delete-orphan"` to maintain referential integrity

**JSON columns:** Store structured data in `_json` fields:
- `emotions_json` - Array of detected emotion labels
- `habits_json` - Array of detected habit objects
- `context_summary_json` - Recommendation generation context
- `action_payload_json` - Recommendation action data

**Async sessions:** Always use `async with get_session() as db:` pattern

### Testing Patterns

**Test structure:** `unittest.IsolatedAsyncioTestCase` for async tests
- In-memory SQLite: `create_async_engine("sqlite+aiosqlite:///:memory:")`
- Fake LLM services for deterministic testing
- Explicit setup/teardown for engine and session lifecycle

**Common test utilities:**
```python
class _FakeLLM:
    async def generate_chat(self, prompt: str, **kwargs) -> str:
        return "Deterministic response"
```

**Run single test:**
```bash
pytest tests/test_conversation_title.py::ConversationTitleGenerationTests::test_generates_title
```

### Configuration

**Environment loading:** `config.py` uses `pydantic-settings` with explicit `load_dotenv()` at module import
- Path resolution: `_BACKEND_DIR / ".env"` ensures `.env` found regardless of cwd
- Validator: `validate_groq_api_key()` checks for placeholder values and warns if invalid

**Settings access:** Always use `get_settings()` cached function
```python
from app.config import get_settings
settings = get_settings()
```

**Required env vars:**
- `GROQ_API_KEY` - Must start with `gsk_` (Groq format)

### API Conventions

**User scoping:** All endpoints require `user_id` in request/query (no auth in MVP)
```python
# Always validate ownership
conversation = await db.get(Conversation, conversation_id)
if conversation.user_id != request.user_id:
    raise HTTPException(status_code=404, detail="Not found")
```

**Response types:**
- Single objects: Return Pydantic model directly
- Collections: Return `list[Model]` (no wrapper needed)
- Streams: SSE with `text/event-stream` content type

**Idempotency:** `POST /conversations/{id}/close` is idempotent (no-op if already closed)

### Chat Memory System

**Conversation lifecycle:**
1. Create conversation → `is_closed=False`
2. Close conversation → Generate summary via LLM, store in `UserChatMemory`, set `is_closed=True`
3. RAG pipeline injects last 10 chat memories into context for continuity

**Memory pruning:** `ChatMemoryService` automatically prunes to `memory_max_items=10` oldest summaries per user

**Backfill script:** For existing closed conversations without summaries:
```bash
cd backend
python scripts/backfill_chat_memories.py
```

### Frontend-Backend Contract

**API base URL:** Hardcoded to `http://localhost:8000` (configure via env for production)

**CORS:** Backend allows localhost dev origins via `CORS_ORIGINS` env var (defaults to ports 5173, 4173)

**Streaming format:**
```
data: {"type": "message_start", "message_id": 42}
data: {"type": "token", "content": "Hello"}
data: {"type": "message_end"}
```

## Safety Notes

- **Never commit `.env`** - Contains `GROQ_API_KEY`
- **Exclude from git:** `*.db`, `*.sqlite3`, `chroma_data/`, `mindpal_graph.json`
- **API key rotation:** If key compromised, regenerate at console.groq.com
- **Local artifacts:** Vector DB and graph state are runtime-generated, not source-controlled
- **Single-tenant MVP:** No authentication implemented; user IDs passed in requests

## Development Tips

**API docs:** Available at `http://localhost:8000/docs` (Swagger) and `/redoc` (ReDoc)

**Hot reload:** Both backend (`uvicorn --reload`) and frontend (`vite`) support hot reload

**Database reset:** Delete `mindpal.db` to start fresh (schema auto-created on startup)

**Vector DB reset:** Delete `chroma_data/` directory to reseed knowledge base

**Graph reset:** Delete `mindpal_graph.json` to rebuild from scratch

**Debug LLM calls:** Set `log_level=DEBUG` in config to see prompts and responses
