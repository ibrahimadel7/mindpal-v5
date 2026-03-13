import type { FormEvent, KeyboardEvent } from 'react'

interface ChatInputProps {
  value: string
  isSending: boolean
  disabled?: boolean
  onOpenToday?: () => void
  onChange: (value: string) => void
  onSend: () => void
}

export default function ChatInput({ value, isSending, disabled = false, onOpenToday, onChange, onSend }: ChatInputProps) {
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

  return (
    <form onSubmit={handleSubmit} className="border-t border-clay-200/70 bg-sand-50/80 px-4 py-4 backdrop-blur sm:px-6">
      <div className="mx-auto w-full max-w-[720px]">
        <div className="flex items-end gap-3 rounded-[1.75rem] border border-clay-200 bg-white px-4 py-3 shadow-soft">
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
            className="max-h-44 min-h-[52px] flex-1 resize-none rounded-soft border-none bg-transparent px-1 py-3 font-body text-[15px] leading-relaxed text-ink-800 placeholder:text-ink-700/60 focus:outline-none"
          />
          <button
            type="submit"
            disabled={disabled || isSending || !value.trim()}
            className="rounded-full bg-clay-200 px-4 py-3 text-sm font-semibold text-ink-900 transition hover:bg-clay-300 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isSending ? '...' : '>'}
          </button>
        </div>
        <div className="mt-2 flex justify-center gap-6 text-[11px] font-semibold uppercase tracking-[0.1em] text-ink-700/65">
          <span>Change Tone</span>
          <span>Save Draft</span>
        </div>
      </div>
    </form>
  )
}
