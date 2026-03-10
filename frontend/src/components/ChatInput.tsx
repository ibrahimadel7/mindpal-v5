import type { FormEvent, KeyboardEvent } from 'react'

interface ChatInputProps {
  value: string
  isSending: boolean
  disabled?: boolean
  onChange: (value: string) => void
  onSend: () => void
}

export default function ChatInput({ value, isSending, disabled = false, onChange, onSend }: ChatInputProps) {
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
