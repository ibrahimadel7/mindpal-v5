const suggestions = [
  'I am feeling overwhelmed with my to-do list today.',
  'I want to process a conversation from yesterday.',
  'Help me pick one thing to focus on right now.',
]

interface SuggestionChipsProps {
  onSelect: (value: string) => void
}

export default function SuggestionChips({ onSelect }: SuggestionChipsProps) {
  return (
    <div className="mt-6 flex flex-wrap gap-2.5">
      {suggestions.map((suggestion) => (
        <button
          key={suggestion}
          type="button"
          onClick={() => onSelect(suggestion)}
          className="max-w-full rounded-[1rem] border border-clay-200 bg-white px-4 py-2.5 text-left text-sm text-ink-700 transition hover:border-clay-300 hover:bg-clay-50"
        >
          {suggestion}
        </button>
      ))}
    </div>
  )
}
