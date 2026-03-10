import type { Conversation } from '../types/api'

interface ReflectionListProps {
  reflections: Conversation[]
  activeId: number | null
  onSelect: (id: number) => void
  onDelete: (id: number) => void
}

export default function ReflectionList({ reflections, activeId, onSelect, onDelete }: ReflectionListProps) {
  if (!reflections.length) {
    return (
      <p className="rounded-soft border border-dashed border-clay-200 bg-sand-50 p-4 text-sm leading-relaxed text-ink-700">
        No reflections yet. Start your first reflection above.
      </p>
    )
  }

  return (
    <ul className="space-y-2">
      {reflections.map((reflection) => {
        const isActive = reflection.id === activeId
        return (
          <li key={reflection.id}>
            <div
              className={`group flex items-center gap-2 rounded-soft border px-3 py-2 transition ${
                isActive
                  ? 'border-clay-300 bg-clay-100 text-ink-900'
                  : 'border-transparent bg-white/70 text-ink-800 hover:border-clay-200 hover:bg-white'
              }`}
            >
              <button type="button" onClick={() => onSelect(reflection.id)} className="min-w-0 flex-1 text-left">
                <p className="truncate text-sm font-semibold">{reflection.title}</p>
                <p className="text-xs text-ink-700/70">{new Date(reflection.created_at).toLocaleDateString()}</p>
              </button>
              <button
                type="button"
                onClick={() => onDelete(reflection.id)}
                className="rounded-full px-2 py-1 text-xs text-ink-700 opacity-0 transition hover:bg-sand-100 hover:text-ink-900 group-hover:opacity-100"
                aria-label="Delete reflection"
              >
                Delete
              </button>
            </div>
          </li>
        )
      })}
    </ul>
  )
}
