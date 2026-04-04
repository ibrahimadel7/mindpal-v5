import type { Message } from '../types/api'

interface MessageBubbleProps {
  message: Message
  isStreaming?: boolean
  thinkingLabel?: string
}

export default function MessageBubble({ message, isStreaming = false, thinkingLabel }: MessageBubbleProps) {
  const isUser = message.role === 'user'
  const timeLabel = new Date(message.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const showThinking = !isUser && isStreaming && message.content.trim().length === 0

  return (
    <div className={`flex w-full ${isUser ? 'justify-end' : 'justify-start'}`}>
      <div className={`flex max-w-[84%] items-start gap-3 ${isUser ? 'flex-row-reverse' : ''}`}>
        {!isUser ? (
          <div className="mt-1.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-clay-200 bg-sand-100 text-xs font-semibold text-ink-700">
            MP
          </div>
        ) : null}

        <article
          className={`animate-rise rounded-bubble px-5 py-4 shadow-soft ${
            isUser
              ? 'rounded-br-md bg-clay-200/85 text-ink-900'
              : 'rounded-bl-md border border-clay-200 bg-white text-ink-900'
          }`}
        >
          <p className="break-words whitespace-pre-wrap text-base leading-relaxed">
            {showThinking ? thinkingLabel ?? 'Thinking...' : message.content}
            {isStreaming && !showThinking ? <span className="ml-0.5 inline-block animate-pulse">|</span> : null}
          </p>
          <p className={`mt-2 text-xs ${isUser ? 'text-ink-700/75' : 'text-ink-700/65'}`}>{timeLabel}</p>
        </article>
      </div>
    </div>
  )
}
