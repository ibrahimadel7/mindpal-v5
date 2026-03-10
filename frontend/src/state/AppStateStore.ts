import { createContext } from 'react'
import type { Conversation, InsightsBundle, Message } from '../types/api'

export interface AppState {
  userId: number
  conversations: Conversation[]
  currentConversationId: number | null
  messagesByConversation: Record<number, Message[]>
  streamingMessageId: number | null
  insights: InsightsBundle
  isInitializing: boolean
  isSending: boolean
  isLoadingInsights: boolean
  isDeleting: boolean
  error: string | null
  initialize: () => Promise<void>
  selectConversation: (id: number | null) => Promise<void>
  createConversation: () => Promise<void>
  removeConversation: (id: number) => Promise<void>
  sendMessage: (content: string) => Promise<void>
  fetchInsights: () => Promise<void>
}

export const AppStateContext = createContext<AppState | undefined>(undefined)
