import type { FormEvent, KeyboardEvent } from 'react'

interface ChatInputProps {
  value: string
  isSending: boolean
  variant?: 'empty' | 'docked'
  disabled?: boolean
  onOpenToday?: () => void
  onChange: (value: string) => void
  onSend: () => void
}

export default function ChatInput({ value, isSending, variant = 'docked', disabled = false, onOpenToday, onChange, onSend }: ChatInputProps) {
  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!value.trim()) {
      return
    }
    onSend()
  }

  const handleKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      if (value.trim()) {
        onSend()
      }
    }
  }

  const isEmptyVariant = variant === 'empty'

  return (
    <form
      onSubmit={handleSubmit}
      className={
        isEmptyVariant
          ? 'w-full animate-rise-delayed'
          : 'border-t border-clay-200/70 bg-sand-50/80 px-4 py-4 backdrop-blur sm:px-6'
      }
    >
      <div className={isEmptyVariant ? 'w-full' : 'mx-auto w-full max-w-[720px]'}>
        <div
          className={
            isEmptyVariant
              ? 'flex items-end gap-3 rounded-card border border-clay-200/90 bg-white/95 px-4 py-3 shadow-soft transition-all duration-300'
              : 'flex items-end gap-3 rounded-card border border-clay-200 bg-white px-4 py-3 shadow-soft'
          }
        >
          {onOpenToday ? (
            <button
              type="button"
              onClick={onOpenToday}
              className="subtle-icon-button mb-1.5 shrink-0"
              aria-label="Open today insights"
              title="Today"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                <path d="M7 3v3" strokeLinecap="round" />
                <path d="M17 3v3" strokeLinecap="round" />
                <path d="M4 9h16" strokeLinecap="round" />
                <rect x="4" y="5" width="16" height="15" rx="3" strokeLinejoin="round" />
              </svg>
            </button>
          ) : null}
          <textarea
            value={value}
            onChange={(event) => onChange(event.target.value)}
            onKeyDown={handleKeyDown}
            disabled={disabled || isSending}
            rows={1}
            placeholder="Type your reflection here..."
            className={
              isEmptyVariant
                ? 'max-h-44 min-h-[60px] flex-1 resize-none rounded-soft border-none bg-transparent px-1 py-3 font-body text-base leading-relaxed text-ink-800 placeholder:text-ink-700/60 focus:outline-none'
                : 'max-h-44 min-h-[56px] flex-1 resize-none rounded-soft border-none bg-transparent px-1 py-3 font-body text-base leading-relaxed text-ink-800 placeholder:text-ink-700/60 focus:outline-none'
            }
          />
          <button
            type="submit"
            disabled={disabled || isSending || !value.trim()}
            className={
              isEmptyVariant
                ? 'rounded-full bg-ink-900 px-4 py-3 text-sm font-semibold text-sand-50 transition hover:bg-ink-800 disabled:cursor-not-allowed disabled:opacity-60'
                : 'rounded-full bg-clay-200 px-4 py-3 text-sm font-semibold text-ink-900 transition hover:bg-clay-300 disabled:cursor-not-allowed disabled:opacity-60'
            }
          >
            {isSending ? '...' : '>'}
          </button>
        </div>

      </div>
    </form>
  )
}
