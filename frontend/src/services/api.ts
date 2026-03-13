import axios from 'axios'
import type {
  ChatRequest,
  ChatResponse,
  Conversation,
  ConversationListResponse,
  ConversationMessagesResponse,
  CreateConversationRequest,
  DailyEmotionTrend,
  DailyHabitTrend,
  EmotionInsight,
  HabitEmotionLinkInsight,
  HabitInsight,
  OverviewInsight,
  DailyHabitChecklistItem,
  DailyHabitChecklistResponse,
  HabitCheckRequest,
  RecommendationBatch,
  RecommendationGenerationRequest,
  RecommendationHistoryResponse,
  RecommendationInteractionRequest,
  TimePatternInsight,
  UserHabit,
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

export async function closeConversation(id: number, userId: number): Promise<Conversation> {
  const { data } = await api.post<Conversation>(`/conversations/${id}/close`, null, {
    params: { user_id: userId },
  })
  return data
}

export async function reopenConversation(id: number, userId: number): Promise<Conversation> {
  const { data } = await api.post<Conversation>(`/conversations/${id}/reopen`, null, {
    params: { user_id: userId },
  })
  return data
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
  response: string
  timestamp: string
}

export interface StreamErrorPayload {
  message?: string
  error_code?: string
  retryable?: boolean
  partial_saved?: boolean
  conversation_id?: number
  assistant_message_id?: number
  response?: string
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

  try {
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
          return
        }
      }
    }

    // Flush any trailing decoded bytes and parse terminal blocks that arrived at EOF.
    buffer += decoder.decode()
    const trailingBlocks = buffer.split(/\r?\n\r?\n/)
    buffer = trailingBlocks.pop() ?? ''

    for (const block of trailingBlocks) {
      processEventBlock(block)
      if (terminalEventSeen) {
        return
      }
    }

    if (buffer.trim()) {
      processEventBlock(buffer)
    }
  } catch {
    handlers.onError?.({ message: 'The stream was interrupted by a network error.' })
    return
  } finally {
    reader.releaseLock()
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

export async function getOverviewInsights(userId: number): Promise<OverviewInsight> {
  const params = { user_id: userId }
  const { data } = await api.get<OverviewInsight>('/insights/overview', { params })
  return data
}

export async function getEmotionTrendInsights(userId: number): Promise<DailyEmotionTrend[]> {
  const params = { user_id: userId }
  const { data } = await api.get<DailyEmotionTrend[]>('/insights/trends/emotions', { params })
  return data
}

export async function getHabitTrendInsights(userId: number): Promise<DailyHabitTrend[]> {
  const params = { user_id: userId }
  const { data } = await api.get<DailyHabitTrend[]>('/insights/trends/habits', { params })
  return data
}

export async function getHabitEmotionLinkInsights(
  userId: number,
  minCount = 1,
  topN = 25,
): Promise<HabitEmotionLinkInsight[]> {
  const params = { user_id: userId, min_count: minCount, top_n: topN }
  const { data } = await api.get<HabitEmotionLinkInsight[]>('/insights/associations/habit-emotion', { params })
  return data
}

export async function getTodayRecommendations(userId: number, category: string): Promise<RecommendationBatch> {
  const params = { user_id: userId, category }
  const { data } = await api.get<RecommendationBatch>('/recommendations/today', { params })
  return data
}

export async function generateRecommendations(
  payload: RecommendationGenerationRequest,
): Promise<RecommendationBatch> {
  const { data } = await api.post<RecommendationBatch>('/recommendations/generate', payload)
  return data
}

export async function getRecommendationHistory(
  userId: number,
  limit = 10,
): Promise<RecommendationHistoryResponse> {
  const params = { user_id: userId, limit }
  const { data } = await api.get<RecommendationHistoryResponse>('/recommendations/history', { params })
  return data
}

export async function selectRecommendationItem(itemId: number, userId: number): Promise<RecommendationBatch['items'][number]> {
  const { data } = await api.post<RecommendationBatch['items'][number]>(`/recommendations/items/${itemId}/select`, null, {
    params: { user_id: userId },
  })
  return data
}

export async function completeRecommendationItem(itemId: number, userId: number): Promise<RecommendationBatch['items'][number]> {
  const { data } = await api.post<RecommendationBatch['items'][number]>(`/recommendations/items/${itemId}/complete`, null, {
    params: { user_id: userId },
  })
  return data
}

export async function logRecommendationItemInteraction(
  itemId: number,
  payload: RecommendationInteractionRequest,
): Promise<void> {
  await api.post(`/recommendations/items/${itemId}/interactions`, payload)
}

export async function adoptRecommendationItem(itemId: number, payload: { user_id: number }): Promise<UserHabit> {
  const { data } = await api.post<UserHabit>(`/recommendations/items/${itemId}/habit`, payload)
  return data
}

export async function getHabitChecklist(userId: number, forDate?: string): Promise<DailyHabitChecklistResponse> {
  const params = forDate ? { user_id: userId, for_date: forDate } : { user_id: userId }
  const { data } = await api.get<DailyHabitChecklistResponse>('/recommendations/habits/checklist', { params })
  return data
}

export async function setHabitCheck(habitId: number, payload: HabitCheckRequest): Promise<DailyHabitChecklistItem> {
  const { data } = await api.put<DailyHabitChecklistItem>(`/recommendations/habits/${habitId}/check`, payload)
  return data
}

export async function createHabit(payload: { user_id: number; name: string }): Promise<UserHabit> {
  const { data } = await api.post<UserHabit>('/recommendations/habits', payload)
  return data
}

export async function deleteHabit(habitId: number, userId: number): Promise<void> {
  await api.delete(`/recommendations/habits/${habitId}`, {
    params: { user_id: userId },
  })
}

export { api }
