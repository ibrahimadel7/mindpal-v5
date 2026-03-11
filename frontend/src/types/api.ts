export type AppTab = 'chat' | 'insights'

export interface Conversation {
  id: number
  user_id: number
  title: string
  created_at: string
}

export interface ConversationListResponse {
  conversations: Conversation[]
}

export interface CreateConversationRequest {
  user_id: number
  title?: string
}

export type MessageRole = 'user' | 'assistant'

export interface Message {
  id: number
  conversation_id: number
  role: MessageRole
  content: string
  timestamp: string
}

export interface ConversationMessagesResponse {
  messages: Message[]
}

export interface ChatRequest {
  user_id: number
  conversation_id: number
  message: string
}

export interface ChatResponse {
  conversation_id: number
  user_message_id: number
  assistant_message_id: number
  response: string
  timestamp: string
}

export interface EmotionInsight {
  label: string
  count: number
}

export interface HabitInsight {
  habit: string
  count: number
}

export interface TimePatternInsight {
  hour_of_day: number
  top_emotion: string
  message_count: number
}

export interface OverviewInsight {
  total_messages: number
  active_days: number
  dominant_emotion: string | null
  dominant_habit: string | null
}

export interface DailyEmotionPoint {
  label: string
  count: number
}

export interface DailyEmotionTrend {
  date: string
  total: number
  emotions: DailyEmotionPoint[]
}

export interface DailyHabitPoint {
  habit: string
  count: number
}

export interface DailyHabitTrend {
  date: string
  total: number
  habits: DailyHabitPoint[]
}

export interface HabitEmotionLinkInsight {
  habit: string
  emotion: string
  co_occurrence: number
  habit_total: number
  link_strength: number
}

export interface InsightsBundle {
  emotions: EmotionInsight[]
  habits: HabitInsight[]
  timePatterns: TimePatternInsight[]
  overview: OverviewInsight | null
  emotionTrends: DailyEmotionTrend[]
  habitTrends: DailyHabitTrend[]
  habitEmotionLinks: HabitEmotionLinkInsight[]
}
