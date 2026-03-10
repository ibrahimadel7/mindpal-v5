import { useEffect, useMemo, useRef, useState } from 'react'
import ChatInput from './ChatInput'
import MessageBubble from './MessageBubble'
import SuggestionChips from './SuggestionChips'
import { useAppState } from '../state/useAppState'

const welcomeText = "Share your thoughts and feelings. I'm here to listen and help you reflect on what matters."

export default function ChatWindow() {
  const [draft, setDraft] = useState('')
  const bottomRef = useRef<HTMLDivElement | null>(null)
  const { currentConversationId, messagesByConversation, sendMessage, isSending, isInitializing } = useAppState()

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
      <section className="flex h-full flex-col">
        <div className="flex flex-1 items-center justify-center px-6">
          <div className="max-w-xl text-center">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-clay-100 text-2xl text-ink-800">
              ○
            </div>
            <h1 className="font-heading text-5xl leading-none text-ink-900">Welcome to MindPal</h1>
            <p className="mt-4 text-base leading-relaxed text-ink-700">{welcomeText}</p>
            <SuggestionChips onSelect={setDraft} />
          </div>
        </div>
        <ChatInput value={draft} onChange={setDraft} onSend={handleSend} isSending={isSending} disabled={false} />
      </section>
    )
  }

  return (
    <section className="flex h-full flex-col">
      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-8">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-3">
          {isInitializing ? <p className="text-sm text-ink-700/70">Loading your reflection...</p> : null}
          {messages.map((message) => (
            <MessageBubble key={`${message.id}-${message.timestamp}`} message={message} />
          ))}
          {isSending ? (
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
