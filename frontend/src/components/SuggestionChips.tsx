const suggestions = ['I\'ve been stressed', 'I had a good day', 'Help me reflect']

interface SuggestionChipsProps {
  onSelect: (value: string) => void
}

export default function SuggestionChips({ onSelect }: SuggestionChipsProps) {
  return (
    <div className="mt-7 flex flex-wrap justify-center gap-2">
      {suggestions.map((suggestion) => (
        <button
          key={suggestion}
          type="button"
          onClick={() => onSelect(suggestion)}
          className="rounded-full border border-clay-200 bg-white/85 px-4 py-2 text-sm text-ink-700 transition hover:border-clay-300 hover:bg-clay-50"
        >
          {suggestion}
        </button>
      ))}
    </div>
  )
}
