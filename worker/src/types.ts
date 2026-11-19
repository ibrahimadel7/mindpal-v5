export interface Env {
  DB: D1Database
  GROQ_API_KEY: string
  GROQ_MODEL: string
  GROQ_EMBEDDING_MODEL: string
  LLM_TEMPERATURE: string
  LLM_MAX_TOKENS: string
  LLM_TIMEOUT_SECONDS: string
  LLM_MAX_RETRIES: string
  ENVIRONMENT: string
  FIREBASE_PROJECT_ID: string
}

export interface ChatRequest {
  user_id: number
  conversation_id: number
  message: string
}

export interface ChatResponse {
  response: string
  conversation_id: number
  user_message_id: number
  assistant_message_id: number
  timestamp: string
}

export interface Conversation {
  id: number
  user_id: number
  title: string
  is_closed: number
  closed_at: string | null
  created_at: string
}

export interface Message {
  id: number
  conversation_id: number
  role: string
  content: string
  timestamp: string
}

export interface ErrorResponse {
  error: string
  detail?: string
}
