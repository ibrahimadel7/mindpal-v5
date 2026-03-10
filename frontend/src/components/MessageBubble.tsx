import type { Message } from '../types/api'

interface MessageBubbleProps {
  message: Message
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === 'user'

  return (
    <div className={`flex w-full ${isUser ? 'justify-end' : 'justify-start'}`}>
      <article
        className={`max-w-[80%] animate-rise rounded-bubble px-4 py-3 shadow-soft ${
          isUser
            ? 'rounded-br-md bg-clay-100 text-ink-800'
            : 'rounded-bl-md border border-clay-200 bg-sand-100 text-ink-900'
        }`}
      >
        <p className="whitespace-pre-wrap text-[15px] leading-relaxed">{message.content}</p>
      </article>
    </div>
  )
}
