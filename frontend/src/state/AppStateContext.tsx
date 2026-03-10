import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  createConversation as createConversationApi,
  deleteConversation as deleteConversationApi,
  getConversationMessages,
  getConversations,
  getEmotionInsights,
  getHabitInsights,
  getTimeInsights,
  streamChat,
} from '../services/api'
import type { Conversation, InsightsBundle, Message } from '../types/api'
import { AppStateContext, type AppState } from './AppStateStore'

const USER_ID = 1
const SELECTED_CONVERSATION_KEY = 'mindpal:selectedConversationId'

function sortConversations(conversations: Conversation[]): Conversation[] {
  return [...conversations].sort((a, b) => Number(new Date(b.created_at)) - Number(new Date(a.created_at)))
}

export function AppStateProvider({ children }: { children: ReactNode }) {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [currentConversationId, setCurrentConversationId] = useState<number | null>(null)
  const [messagesByConversation, setMessagesByConversation] = useState<Record<number, Message[]>>({})
  const [streamingMessageId, setStreamingMessageId] = useState<number | null>(null)
  const [insights, setInsights] = useState<InsightsBundle>({ emotions: [], habits: [], timePatterns: [] })
  const [isInitializing, setIsInitializing] = useState(true)
  const [isSending, setIsSending] = useState(false)
  const [isLoadingInsights, setIsLoadingInsights] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadConversationMessages = useCallback(async (conversationId: number) => {
    const response = await getConversationMessages(conversationId, USER_ID)
    setMessagesByConversation((prev) => ({
      ...prev,
      [conversationId]: response.messages,
    }))
  }, [])

  const selectConversation = useCallback(
    async (id: number | null) => {
      setCurrentConversationId(id)
      if (id === null) {
        localStorage.removeItem(SELECTED_CONVERSATION_KEY)
        return
      }
      localStorage.setItem(SELECTED_CONVERSATION_KEY, String(id))
      await loadConversationMessages(id)
    },
    [loadConversationMessages],
  )

  const initialize = useCallback(async () => {
    setIsInitializing(true)
    setError(null)
    try {
      const list = await getConversations(USER_ID)
      const sorted = sortConversations(list)
      setConversations(sorted)

      const storedId = localStorage.getItem(SELECTED_CONVERSATION_KEY)
      const fallbackId = sorted[0]?.id ?? null
      const parsedStoredId = storedId ? Number(storedId) : null
      const hasStored = parsedStoredId && sorted.some((conversation) => conversation.id === parsedStoredId)
      const nextId = hasStored ? parsedStoredId : fallbackId

      if (nextId) {
        setCurrentConversationId(nextId)
        await loadConversationMessages(nextId)
      } else {
        setCurrentConversationId(null)
      }
    } catch {
      setError('Unable to load your reflections right now.')
    } finally {
      setIsInitializing(false)
    }
  }, [loadConversationMessages])

  useEffect(() => {
    void initialize()
  }, [initialize])

  const createConversation = useCallback(async () => {
    setError(null)
    try {
      const created = await createConversationApi({ user_id: USER_ID, title: 'New Reflection' })
      setConversations((prev) => sortConversations([created, ...prev]))
      await selectConversation(created.id)
    } catch {
      setError('Could not create a new reflection.')
    }
  }, [selectConversation])

  const removeConversation = useCallback(
    async (id: number) => {
      setError(null)
      setIsDeleting(true)
      try {
        await deleteConversationApi(id)
        const refreshed = sortConversations(await getConversations(USER_ID))
        setConversations(refreshed)
        setMessagesByConversation((prev) => {
          const rest = Object.fromEntries(Object.entries(prev).filter(([key]) => Number(key) !== id)) as Record<
            number,
            Message[]
          >
          return rest
        })

        if (currentConversationId === id) {
          const nextId = refreshed[0]?.id ?? null
          await selectConversation(nextId)
        }

        const [emotions, habits, timePatterns] = await Promise.all([
          getEmotionInsights(USER_ID),
          getHabitInsights(USER_ID),
          getTimeInsights(USER_ID),
        ])
        setInsights({ emotions, habits, timePatterns })
      } catch {
        setError('Could not delete this reflection.')
      } finally {
        setIsDeleting(false)
      }
    },
    [currentConversationId, selectConversation],
  )

  const sendMessage = useCallback(
    async (content: string) => {
      if (!content.trim()) {
        return
      }

      let conversationId = currentConversationId

      if (!conversationId) {
        try {
          const created = await createConversationApi({ user_id: USER_ID, title: 'New Reflection' })
          setConversations((prev) => sortConversations([created, ...prev]))
          conversationId = created.id
          setCurrentConversationId(created.id)
          localStorage.setItem(SELECTED_CONVERSATION_KEY, String(created.id))
          setMessagesByConversation((prev) => ({ ...prev, [created.id]: [] }))
        } catch {
          setError('Could not create a new reflection.')
          return
        }
      }

      const userMessage: Message = {
        id: Date.now(),
        conversation_id: conversationId,
        role: 'user',
        content,
        timestamp: new Date().toISOString(),
      }

      setMessagesByConversation((prev) => ({
        ...prev,
        [conversationId]: [...(prev[conversationId] ?? []), userMessage],
      }))

      setIsSending(true)
      setError(null)
      let tempAssistantId: number | null = null

      try {
        tempAssistantId = -Date.now()
        const assistantDraft: Message = {
          id: tempAssistantId,
          conversation_id: conversationId,
          role: 'assistant',
          content: '',
          timestamp: new Date().toISOString(),
        }

        setMessagesByConversation((prev) => ({
          ...prev,
          [conversationId]: [...(prev[conversationId] ?? []), assistantDraft],
        }))
        setStreamingMessageId(tempAssistantId)

        // We stream tokens to reduce perceived latency and make the UI feel responsive.
        await streamChat(
          {
            user_id: USER_ID,
            conversation_id: conversationId,
            message: content,
          },
          {
            onToken: (token) => {
              setMessagesByConversation((prev) => ({
                ...prev,
                [conversationId]: (prev[conversationId] ?? []).map((message) =>
                  message.id === tempAssistantId ? { ...message, content: `${message.content}${token}` } : message,
                ),
              }))
            },
            onDone: (payload) => {
              setMessagesByConversation((prev) => ({
                ...prev,
                [conversationId]: (prev[conversationId] ?? []).map((message) =>
                  message.id === tempAssistantId
                    ? {
                        ...message,
                        id: payload.assistant_message_id,
                        timestamp: payload.timestamp,
                      }
                    : message,
                ),
              }))
            },
            onError: (payload) => {
              if (typeof payload.assistant_message_id === 'number' && typeof payload.timestamp === 'string') {
                const persistedId = payload.assistant_message_id
                const persistedTimestamp = payload.timestamp
                setMessagesByConversation((prev) => ({
                  ...prev,
                  [conversationId]: (prev[conversationId] ?? []).map((message) =>
                    message.id === tempAssistantId
                      ? {
                          ...message,
                          id: persistedId,
                          timestamp: persistedTimestamp,
                        }
                      : message,
                  ),
                }))
              }
              setError(payload.message ?? 'The response stream was interrupted. Partial output was saved.')
            },
          },
        )
      } catch {
        setError('Your reflection could not be sent. Please try again.')
        if (tempAssistantId !== null) {
          setMessagesByConversation((prev) => ({
            ...prev,
            [conversationId]: (prev[conversationId] ?? []).filter((message) => message.id !== tempAssistantId),
          }))
        }
      } finally {
        setStreamingMessageId(null)
        setIsSending(false)
      }
    },
    [currentConversationId],
  )

  const fetchInsights = useCallback(async () => {
    setIsLoadingInsights(true)
    setError(null)
    try {
      const [emotions, habits, timePatterns] = await Promise.all([
        getEmotionInsights(USER_ID),
        getHabitInsights(USER_ID),
        getTimeInsights(USER_ID),
      ])
      setInsights({ emotions, habits, timePatterns })
    } catch {
      setError('Insights are unavailable at the moment.')
    } finally {
      setIsLoadingInsights(false)
    }
  }, [])

  const value = useMemo<AppState>(
    () => ({
      userId: USER_ID,
      conversations,
      currentConversationId,
      messagesByConversation,
      streamingMessageId,
      insights,
      isInitializing,
      isSending,
      isLoadingInsights,
      isDeleting,
      error,
      initialize,
      selectConversation,
      createConversation,
      removeConversation,
      sendMessage,
      fetchInsights,
    }),
    [
      conversations,
      currentConversationId,
      messagesByConversation,
      streamingMessageId,
      insights,
      isInitializing,
      isSending,
      isLoadingInsights,
      isDeleting,
      error,
      initialize,
      selectConversation,
      createConversation,
      removeConversation,
      sendMessage,
      fetchInsights,
    ],
  )

  return <AppStateContext.Provider value={value}>{children}</AppStateContext.Provider>
}
