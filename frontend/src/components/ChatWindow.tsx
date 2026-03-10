import { useEffect, useMemo, useRef, useState } from 'react'
import ChatInput from './ChatInput'
import MessageBubble from './MessageBubble'
import SuggestionChips from './SuggestionChips'
import { useAppState } from '../state/useAppState'

const welcomeText = "Good morning. Take a moment to check in with yourself. How are you feeling as you start your day?"

interface ChatWindowProps {
  onOpenNavigation?: () => void
  onOpenInsights?: () => void
}

export default function ChatWindow({ onOpenNavigation, onOpenInsights }: ChatWindowProps) {
  const [draft, setDraft] = useState('')
  const bottomRef = useRef<HTMLDivElement | null>(null)
  const { currentConversationId, messagesByConversation, sendMessage, isSending, isInitializing, streamingMessageId } =
    useAppState()

  const messages = useMemo(() => {
    if (!currentConversationId) {
      return []
    }
    return messagesByConversation[currentConversationId] ?? []
  }, [currentConversationId, messagesByConversation])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isSending])

  const handleSend = () => {
    const trimmed = draft.trim()
    if (!trimmed) {
      return
    }
    setDraft('')
    void sendMessage(trimmed)
  }

  if (!currentConversationId) {
    return (
      <section className="flex h-full min-h-0 flex-col">
        <header className="flex items-center justify-between border-b border-clay-200/70 px-4 py-3 sm:px-6">
          <div className="flex items-center gap-2">
            {onOpenNavigation ? (
              <button
                type="button"
                onClick={onOpenNavigation}
                className="subtle-icon-button"
                aria-label="Open sidebar"
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                  <path d="M4 7h16" strokeLinecap="round" />
                  <path d="M4 12h16" strokeLinecap="round" />
                  <path d="M4 17h16" strokeLinecap="round" />
                </svg>
              </button>
            ) : null}
            <button
              type="button"
              onClick={onOpenInsights}
              className="rounded-full border border-clay-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700"
            >
              Today
            </button>
          </div>
          <div>
            <p className="text-lg font-semibold text-ink-900">Today's Reflection</p>
            <p className="text-xs text-ink-700/75">Take your first mindful minute.</p>
          </div>
          <div className="hidden gap-2 lg:flex">
            <button type="button" className="rounded-full border border-clay-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700">
              Share
            </button>
            <button type="button" className="rounded-full border border-clay-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700">
              More
            </button>
          </div>
        </header>

        <div className="flex flex-1 items-center justify-center px-6 py-8">
          <div className="w-full max-w-[720px]">
            <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-full border border-clay-200 bg-sand-100 text-sm text-ink-700">
              *
            </div>
            <h1 className="max-w-2xl text-[34px] font-semibold leading-tight text-ink-900">{welcomeText}</h1>
            <p className="mt-4 max-w-xl text-base leading-relaxed text-ink-700">
              Sometimes just putting words to feelings can create space. Don't worry about perfect sentences, let it flow.
            </p>
            <SuggestionChips onSelect={setDraft} />
          </div>
        </div>
        <ChatInput value={draft} onChange={setDraft} onSend={handleSend} isSending={isSending} disabled={false} />
      </section>
    )
  }

  return (
    <section className="flex h-full min-h-0 flex-col">
      <header className="flex items-center justify-between border-b border-clay-200/70 px-4 py-3 sm:px-6">
        <div className="flex items-center gap-2">
          {onOpenNavigation ? (
            <button
              type="button"
              onClick={onOpenNavigation}
              className="subtle-icon-button"
              aria-label="Open sidebar"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                <path d="M4 7h16" strokeLinecap="round" />
                <path d="M4 12h16" strokeLinecap="round" />
                <path d="M4 17h16" strokeLinecap="round" />
              </svg>
            </button>
          ) : null}
          <button
            type="button"
            onClick={onOpenInsights}
            className="rounded-full border border-clay-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700"
          >
            Today
          </button>
        </div>
        <div>
          <p className="text-lg font-semibold text-ink-900">Today's Reflection</p>
          <p className="text-xs text-ink-700/75">Keep writing. You're doing meaningful work.</p>
        </div>
        <div className="hidden gap-2 lg:flex">
          <button type="button" className="rounded-full border border-clay-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700">
            Share
          </button>
          <button type="button" className="rounded-full border border-clay-200 bg-white px-3 py-1.5 text-xs font-semibold text-ink-700">
            More
          </button>
        </div>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-4 py-8 sm:px-6">
        <div className="mx-auto flex w-full max-w-[720px] flex-col gap-6">
          {isInitializing ? <p className="text-sm text-ink-700/70">Loading your reflection...</p> : null}
          {messages.map((message) => (
            <MessageBubble
              key={`${message.id}-${message.timestamp}`}
              message={message}
              isStreaming={message.role === 'assistant' && message.id === streamingMessageId}
            />
          ))}
          {isSending && !streamingMessageId ? (
            <div className="flex justify-start">
              <div className="rounded-bubble rounded-bl-md border border-clay-200 bg-sand-100 px-4 py-2 text-sm text-ink-700">
                MindPal is reflecting...
              </div>
            </div>
          ) : null}
          <div ref={bottomRef} />
        </div>
      </div>
      <ChatInput value={draft} onChange={setDraft} onSend={handleSend} isSending={isSending} disabled={!currentConversationId} />
    </section>
  )
}
