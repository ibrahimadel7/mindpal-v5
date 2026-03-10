# MindPal Backend

Backend for a personalized mental health RAG chatbot built with FastAPI, SQLite, Chroma, NetworkX, and Groq.

## Features

- FastAPI async API endpoints
- SQLite structured storage via SQLAlchemy ORM
- Chroma vector retrieval for RAG
- NetworkX graph relationships for behavior insights
- LLM-based emotion and habit detection via Groq
- Temporal analytics for hour/day trends

## Project Structure

```text
backend/
  app/
    main.py
    config.py
    database/
    models/
    schemas/
    services/
    rag/
    analytics/
    api/
  requirements.txt
```

## Setup

1. Create and activate a Python 3.11+ virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Copy env file and set `GROQ_API_KEY`:

```bash
cp .env.example .env
```

4. Run API:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

- `POST /chat`
- `GET /conversations`
- `POST /conversations`
- `DELETE /conversations/{id}`
- `GET /insights/emotions`
- `GET /insights/habits`
- `GET /insights/time`
- `GET /insights/summary`

## Notes

- Knowledge base documents are seeded on startup into Chroma.
- Graph state is persisted to `mindpal_graph.json`.
- This iteration is single-tenant MVP scope (no auth).
