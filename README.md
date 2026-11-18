# MindPal

A personalized mental health RAG chatbot that combines real-time conversation analysis, emotion tracking, and behavioral insights to support mental wellness across backend and Flutter clients.

## Overview

MindPal includes a FastAPI backend and a Flutter mobile/desktop client. Together they provide:

- **Real-time Chat Analysis**: Process conversations with LLM-powered emotion and habit detection
- **Vector-based Retrieval (RAG)**: Semantic search over a knowledge base using Chroma
- **Behavioral Insights**: Track temporal patterns, emotional trends, and habit formation via NetworkX graph relationships
- **Persistent Storage**: SQLAlchemy ORM with SQLite for structured data management
- **Cross-platform Client**: Flutter app targeting Android, iOS, Web, Windows, Linux, and macOS

## Architecture

```
MindPal (Root)
├── app/                          # Flutter application
│   ├── lib/                      # Features, routing, state, UI
│   ├── test/                     # Widget/unit tests
│   ├── android/ ios/ web/
│   ├── windows/ linux/ macos/    # Platform runners
│   └── pubspec.yaml              # Flutter dependencies & assets
├── backend/                      # FastAPI application server
│   ├── app/
│   │   ├── api/                 # REST endpoints (chat, conversations, insights)
│   │   ├── services/            # Business logic (LLM, vector, emotion, habits, graphs)
│   │   ├── models/              # SQLAlchemy ORM models
│   │   ├── schemas/             # Pydantic request/response schemas
│   │   ├── database/            # ORM session & connection management
│   │   ├── rag/                 # Knowledge base seeding & retrieval pipeline
│   │   ├── analytics/           # Temporal & behavioral analysis
│   │   ├── config.py            # Configuration loader
│   │   └── main.py              # FastAPI app initialization
│   ├── chroma_data/             # Local vector database (runtime-generated)
│   ├── requirements.txt
│   └── README.md                # Backend-specific setup & endpoints
├── frontend/                     # React web client (legacy/alternate UI)
└── README.md                     # This file
```

## Quick Start

### Prerequisites

- Python 3.11+
- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Groq API key (sign up at [console.groq.com](https://console.groq.com))

### Setup

1. **Clone and navigate to workspace:**
   ```bash
   cd mindpal-v5  # or your local clone path
   ```

2. **Create and activate a virtual environment:**
   ```bash
   python -m venv .venv
   # On Windows:
   .venv\Scripts\Activate.ps1
   # On macOS/Linux:
   source .venv/bin/activate
   ```

3. **Install backend dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

4. **Set environment variables:**
   ```bash
   # Windows PowerShell
   Copy-Item .env.example .env
   # macOS/Linux
   cp .env.example .env
   # Edit .env and add your GROQ_API_KEY
   ```

5. **Run the API server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

   The API will be available at `http://localhost:8000`.

6. **Run the Flutter app (new terminal):**
   ```bash
   cd ../app
   flutter pub get
   flutter run
   ```

   Notes:
   - Use `flutter devices` to list available targets.
   - For web, you can run `flutter run -d chrome`.

7. **Optional: Run the React frontend (new terminal):**
   ```bash
   cd ../frontend
   npm install
   npm run dev
   ```

   The frontend will be available at `http://localhost:5173`.

## API Endpoints

### Chat Management
- `POST /chat` — Send a message and receive an analysis + response
- `GET /conversations` — List all conversations
- `POST /conversations` — Create a new conversation
- `DELETE /conversations/{id}` — Delete a conversation

### Insights
- `GET /insights/emotions` — Summary of emotional patterns
- `GET /insights/habits` — Detected behavioral habits
- `GET /insights/time` — Temporal activity analysis (hour/day trends)
- `GET /insights/summary` — Consolidated user insights

## Backend Details

For backend-specific configuration, service documentation, and implementation details, see [backend/README.md](backend/README.md).

## Key Features

- **AsyncIO-based FastAPI** for high-concurrency chat API
- **Flutter client app** for cross-platform user experiences
- **SQLite + SQLAlchemy** for structured conversation & user data
- **Chroma Vector Database** for semantic knowledge retrieval
- **Groq LLM** for real-time emotion and habit classification
- **NetworkX** for behavior graph relationships and pattern discovery
- **Single-tenant MVP** (authentication not included in this iteration)

## Project Notes

- Knowledge base documents are automatically seeded into Chroma on first startup.
- Graph state is persisted to `mindpal_graph.json` for reproducibility.
- Local vector DB and generated artifacts are excluded from version control for production cleanliness.

## Safety Notes

- Never commit `.env` files or API keys. Use `.env.example` as the template for shared configuration.
- Keep local databases (`*.db`, `*.sqlite3`) and vector stores (`backend/chroma_data/`) out of git.
- Validate incoming data at API boundaries and avoid logging secrets in request/response payloads.

## Development

- View API documentation at `http://localhost:8000/docs` (Swagger UI)
- View alternate docs at `http://localhost:8000/redoc` (ReDoc)
- For Flutter development, run `flutter doctor` and ensure all platform toolchains are configured.



## Contributing

Contributions welcome! Please open issues or pull requests.
