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
    <form onSubmit={handleSubmit} className="border-t border-clay-100 bg-sand-50/85 px-6 py-4 backdrop-blur">
      <div className="mx-auto flex w-full max-w-3xl items-end gap-3 rounded-soft border border-clay-200 bg-white p-2 shadow-soft">
        <textarea
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onKeyDown={handleKeyDown}
          disabled={disabled || isSending}
          rows={1}
          placeholder="Share your thoughts..."
          className="max-h-44 min-h-[52px] flex-1 resize-none rounded-soft border-none bg-transparent px-3 py-3 font-body text-[15px] leading-relaxed text-ink-800 placeholder:text-ink-700/65 focus:outline-none"
        />
        <button
          type="submit"
          disabled={disabled || isSending || !value.trim()}
          className="rounded-full bg-clay-300 px-4 py-2 text-sm font-semibold text-ink-900 transition hover:bg-clay-400 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isSending ? 'Sending...' : 'Send'}
        </button>
      </div>
    </form>
  )
}
