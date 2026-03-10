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
