import type { Message } from '../types/api'

interface MessageBubbleProps {
  message: Message
  isStreaming?: boolean
}

export default function MessageBubble({ message, isStreaming = false }: MessageBubbleProps) {
  const isUser = message.role === 'user'
  const timeLabel = new Date(message.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })

  return (
    <div className={`flex w-full ${isUser ? 'justify-end' : 'justify-start'}`}>
      <div className={`flex max-w-[84%] items-start gap-2 ${isUser ? 'flex-row-reverse' : ''}`}>
        {!isUser ? (
          <div className="mt-1.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-clay-200 bg-sand-100 text-xs font-semibold text-ink-700">
            MP
          </div>
        ) : null}

        <article
          className={`animate-rise rounded-[1.35rem] px-4 py-3 shadow-soft ${
            isUser
              ? 'rounded-br-md bg-clay-200/85 text-ink-900'
              : 'rounded-bl-md border border-clay-200 bg-white text-ink-900'
          }`}
        >
          <p className="break-words whitespace-pre-wrap text-[15px] leading-relaxed">
            {message.content}
            {isStreaming ? <span className="ml-0.5 inline-block animate-pulse">|</span> : null}
          </p>
          <p className={`mt-2 text-[11px] ${isUser ? 'text-ink-700/75' : 'text-ink-700/65'}`}>{timeLabel}</p>
        </article>
      </div>
    </div>
  )
}
