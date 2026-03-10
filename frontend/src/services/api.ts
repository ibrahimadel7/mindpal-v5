import axios from 'axios'
import type {
  ChatRequest,
  ChatResponse,
  Conversation,
  ConversationListResponse,
  ConversationMessagesResponse,
  CreateConversationRequest,
  EmotionInsight,
  HabitInsight,
  TimePatternInsight,
} from '../types/api'

const baseURL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000'

const api = axios.create({
  baseURL,
  timeout: 15000,
})

export async function getConversations(userId?: number): Promise<Conversation[]> {
  const params = userId ? { user_id: userId } : undefined
  const { data } = await api.get<ConversationListResponse>('/conversations', { params })
  return data.conversations
}

export async function createConversation(payload: CreateConversationRequest): Promise<Conversation> {
  const { data } = await api.post<Conversation>('/conversations', payload)
  return data
}

export async function deleteConversation(id: number): Promise<void> {
  await api.delete(`/conversations/${id}`)
}

export async function getConversationMessages(conversationId: number, userId: number): Promise<ConversationMessagesResponse> {
  const { data } = await api.get<ConversationMessagesResponse>(`/conversations/${conversationId}/messages`, {
    params: { user_id: userId },
  })
  return data
}

export async function sendChat(payload: ChatRequest): Promise<ChatResponse> {
  const { data } = await api.post<ChatResponse>('/chat', payload)
  return data
}

export interface StreamEndPayload {
  conversation_id: number
  assistant_message_id: number
  timestamp: string
}

export interface StreamErrorPayload {
  message?: string
  conversation_id?: number
  assistant_message_id?: number
  timestamp?: string
}

export interface StreamChatHandlers {
  onStart?: (payload: { conversation_id: number; user_message_id: number }) => void
  onToken?: (token: string) => void
  onDone?: (payload: StreamEndPayload) => void
  onError?: (payload: StreamErrorPayload) => void
}

export async function streamChat(payload: ChatRequest, handlers: StreamChatHandlers): Promise<void> {
  const response = await fetch(`${baseURL}/chat/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
    },
    body: JSON.stringify(payload),
  })

  if (!response.ok) {
    const detail = await response.text()
    throw new Error(detail || `Streaming request failed with status ${response.status}`)
  }

  if (!response.body) {
    throw new Error('Streaming response body is unavailable')
  }

  const reader = response.body.getReader()
  const decoder = new TextDecoder('utf-8')
  let buffer = ''
  let terminalEventSeen = false

  const processEventBlock = (block: string) => {
    const lines = block.split('\n')
    let eventType = 'message'
    const dataLines: string[] = []

    for (const line of lines) {
      if (line.startsWith('event:')) {
        eventType = line.slice(6).trim()
      } else if (line.startsWith('data:')) {
        dataLines.push(line.slice(5).trimStart())
      }
    }

    if (dataLines.length === 0) {
      return
    }

    const raw = dataLines.join('\n')
    let parsed: unknown = {}
    try {
      parsed = JSON.parse(raw)
    } catch {
      parsed = { message: raw }
    }

    if (eventType === 'message_start') {
      const data = parsed as { conversation_id: number; user_message_id: number }
      handlers.onStart?.(data)
      return
    }

    if (eventType === 'token') {
      const data = parsed as { token?: string }
      if (data.token) {
        handlers.onToken?.(data.token)
      }
      return
    }

    if (eventType === 'message_end') {
      terminalEventSeen = true
      handlers.onDone?.(parsed as StreamEndPayload)
      return
    }

    if (eventType === 'error') {
      terminalEventSeen = true
      handlers.onError?.(parsed as StreamErrorPayload)
      return
    }
  }

  while (true) {
    const { value, done } = await reader.read()
    if (done) {
      break
    }

    buffer += decoder.decode(value, { stream: true })
    const blocks = buffer.split(/\r?\n\r?\n/)
    buffer = blocks.pop() ?? ''

    for (const block of blocks) {
      processEventBlock(block)
      if (terminalEventSeen) {
        await reader.cancel()
        return
      }
    }
  }

  if (!terminalEventSeen) {
    handlers.onError?.({ message: 'The stream ended unexpectedly.' })
  }
}

export async function getEmotionInsights(userId: number): Promise<EmotionInsight[]> {
  const params = { user_id: userId }
  const { data } = await api.get<EmotionInsight[]>('/insights/emotions', { params })
  return data
}

export async function getHabitInsights(userId: number): Promise<HabitInsight[]> {
  const params = { user_id: userId }
  const { data } = await api.get<HabitInsight[]>('/insights/habits', { params })
  return data
}

export async function getTimeInsights(userId: number): Promise<TimePatternInsight[]> {
  const params = { user_id: userId }
  const { data } = await api.get<TimePatternInsight[]>('/insights/time', { params })
  return data
}

export { api }
