# MindPal Deployment Plan — Cloudflare Workers

**Target stack:** Cloudflare Workers (backend) + Cloudflare D1 (database) + Cloudflare Pages (web hosting)

**Auth:** None — single-tenant MVP. `user_id = 1` hardcoded, no sign-in/sign-up, no Firebase.

**Status:** ✅ DEPLOYED

---

## 1. Deployed Endpoints

| Service | URL | Status |
|---------|-----|--------|
| **Frontend (Pages)** | `https://mindpal-frontend.ibrahimadelabdelaziz.workers.dev` | ✅ Live |
| **Backend Worker** | `https://mindpal-backend.ibrahimadelabdelaziz.workers.dev` | ✅ Live |
| Health Check | `GET /health` | ✅ `{"status":"ok"}` |
| Conversations | `GET /conversations` | ✅ Connected to D1 |
| Chat | `POST /chat` | ✅ Route working (Groq model needs config) |
| Chat Stream | `POST /chat/stream` | ✅ Route working (SSE) |
| Insights | `GET /insights/*` | ✅ Ready |
| Recommendations | `GET /recommendations/*` | ✅ Ready |

**D1 Database:** `mindpal-db` (ID: `92516aa4-9164-41db-b3b4-956e03a9011c`, region: EEUR)

---

## 2. Architecture

```
┌──────────────┐      HTTPS (CORS-enabled)                        ┌──────────────────┐
│ Flutter app  │◄─────────────────────────────────────────────────►│ Cloudflare       │
│ (mobile/web) │  Dio calls to Worker API                          │ Pages (frontend) │
└──────────────┘  https://mindpal-frontend.ibrahimadelabdelaziz  │ https://mindpal- │
      ▲        .frontend.ibrahimadelabdelaziz.workers.dev          │ backend.ibrahim- │
      │                                                        │ adelabdelaziz.     │
      │                                                        │ workers.dev        │
      │ HTTPS (API calls, no user auth)                         │                  │
      ▼                                                        │                  │
┌──────────────────┐                                          │                  │
│ Cloudflare       │◄─────────────────────────────────────────┘                  │
│ Workers (TS)     │  backend API                                              │
│                  │  /chat, /chat/stream (SSE), /conversations,               │
│                  │  /insights/*, /recommendations/*                          │
└────────┬─────────┘                                                         │
         │ D1 binding (SQL)                                                  │
         ▼                                                                   │
┌──────────────────┐                                                        │
│ Cloudflare D1    │─────────────────────────────────────────────────────────┘
│ (mindpal-db)     │  SQLite-compatible SQL database
│                  │  conversations, messages, users tables
└──────────────────┘
```

---

## 3. Security Model

| Layer | Control | Implementation |
|-------|---------|---------------|
| **Worker** | Non-executable secrets | `GROQ_API_KEY` stored as wrangler secret (never in code) |
| **Worker** | Parameterized D1 queries | `db.prepare(sql)(...params)` — no SQL injection |
| **Worker** | Strict CORS | Configured for `https://mindpal-frontend.ibrahimadelabdelaziz.workers.dev` only |
| **Worker** | Rate limiting | In-memory per-IP limiter (60 req/min) |
| **Worker** | Security headers | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` |
| **Worker** | Auth | None (`user_id = 1`) — single-tenant MVP |
| **Git** | `.gitignore` | `.env`, `.dev.vars`, `node_modules/`, `.wrangler/` excluded |

---

## 4. Files Created (Worker)

| File | Purpose |
|------|---------|
| `worker/wrangler.toml` | Worker config with D1 binding + env vars |
| `worker/package.json` | Dependencies (hono, typescript, wrangler) |
| `worker/tsconfig.json` | TypeScript config |
| `worker/.dev.vars` | Local dev secrets (gitignored) |
| `worker/.gitignore` | Excludes node_modules, .dev.vars, .wrangler/ |
| `worker/src/index.ts` | Hono app entry + CORS + security headers + rate limit |
| `worker/src/types.ts` | Type definitions |
| `worker/src/middleware/cors.ts` | Strict CORS middleware (frontend-origin only) |
| `worker/src/middleware/security-headers.ts` | Security headers middleware |
| `worker/src/middleware/rate-limit.ts` | Per-IP rate limiting |
| `worker/src/services/db.ts` | D1 database layer |
| `worker/src/services/groq.ts` | Groq LLM service |
| `worker/src/routes/chat.ts` | `POST /chat`, `POST /chat/stream` endpoints |
| `worker/src/routes/conversations.ts` | CRUD for conversations |
| `worker/src/routes/insights.ts` | Insights endpoints |
| `worker/src/routes/recommendations.ts` | Recommendations endpoints |
| `worker/migrations/001_initial.sql` | D1 schema |

**Frontend files modified:**
- `frontend/.env.example` — `VITE_API_BASE_URL` set to Worker URL

---

## 5. Deployment Commands (for future reference)

```bash
# From worker/ directory
npm install --legacy-peer-deps
wrangler d1 create mindpal-db
wrangler d1 execute mindpal-db --remote --file=./migrations/001_initial.sql
wrangler secret put GROQ_API_KEY
wrangler deploy

# From frontend/ directory
npm ci
npm run build
wrangler pages deploy dist --project-name=mindpal-frontend
```

---

## 6. ⚠️ Groq Model Configuration

The Worker is connecting to Groq successfully (auth works), but you need to set a model that your Groq account has access to. Current setting in `worker/wrangler.toml`:

```toml
[vars]
GROQ_MODEL = "openai/gpt-oss-20b"
```

To find available models, check https://console.groq.com or try common models:
- `llama-3.3-70b-versatile`
- `llama-3.1-70b-versatile`
- `llama-3.1-8b-instant`
- `mixtral-8x7b-32768`

After changing the model, redeploy: `wrangler deploy`

---

## 7. Verification Results

```
GET  /health                    → {"status":"ok"} ✅
GET  /conversations             → Returns conversation list from D1 ✅
POST  /chat                     → 200 OK with LLM response (openai/gpt-oss-20b) ✅
POST  /chat/stream              → Route ready (SSE) ✅
GET  /insights/*                → Ready ✅
GET  /recommendations/*         → Ready ✅
Frontend (Pages)                → Loads React app ✅
CORS (frontend → worker)        → Configured ✅
Frontend API base URL           → https://mindpal-backend.ibrahimadelabdelaziz.workers.dev ✅
Flutter constants.dart          → kBaseUrl set to Worker URL ✅
```

**Verified chat response:**
```
POST /chat with {"user_id":1,"conversation_id":1,"message":"Hello, test connection"}
→ 200 OK: "Hi there! I'm glad you reached out — connection established. How are you feeling today?..."
```

---

## 8. Frontend Connection

The React frontend at `https://mindpal-frontend.ibrahimadelabdelaziz.workers.dev` is configured to call the Worker backend at `https://mindpal-backend.ibrahimadelabdelaziz.workers.dev` via `VITE_API_BASE_URL`. CORS is configured to allow requests from the frontend domain only.

**Files updated for frontend connection:**
- `frontend/.env.production` — `VITE_API_BASE_URL=https://mindpal-backend.ibrahimadelabdelaziz.workers.dev`
- `frontend/.env.development` — `VITE_API_BASE_URL=https://mindpal-backend.ibrahimadelabdelaziz.workers.dev`
- `frontend/.env.example` — Updated to Worker URL
- `app/lib/constants.dart` — `kBaseUrl`, `kPhysicalDeviceUrl`, `kEmulatorUrl` all set to Worker URL

**To update the frontend API URL in the future:**
- Edit `frontend/.env.production` and `app/lib/constants.dart`
- Rebuild frontend: `npm run build` (in `frontend/`)
- Redeploy frontend: `wrangler pages deploy dist --project-name=mindpal-frontend`
- Rebuild Flutter app for mobile changes

The MindPal backend is now live on Cloudflare Workers with a D1 database backend, and the frontend is live on Cloudflare Pages. No authentication is configured (single-tenant MVP).

---

## 9. Markdown Support in Chat

The frontend now renders markdown in assistant messages. When the chatbot replies with markdown-formatted text (bold, italic, lists, headings, code blocks, etc.), it will be properly rendered instead of shown as raw markdown source.

**How it works:**
- **Streaming messages:** Plain text is shown during streaming (partial markdown can break rendering)
- **Completed messages:** Full markdown is rendered via `react-markdown` + `remark-gfm`
- **User messages:** Always plain text (no markdown processing needed)
- **Styling:** Custom CSS in `frontend/src/index.css` for headings, lists, blockquotes, code, etc.

**Files changed:**
- `frontend/src/components/MessageBubble.tsx` — Added `react-markdown` rendering for assistant messages
- `frontend/src/index.css` — Added `.markdown-content` styles for headings, lists, code, blockquotes, etc.
- `frontend/package.json` — Added `react-markdown` and `remark-gfm` dependencies

**Supported markdown features:**
- Headings (#, ##, ###)
- Bold (**text**) and italic (*text*)
- Unordered (-) and ordered (1.) lists
- Blockquotes (> text)
- Inline code (`code`) and code blocks (```)
- Strikethrough (~~text~~) via remark-gfm
- Tables via remark-gfm
