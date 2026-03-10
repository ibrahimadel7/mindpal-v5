import type { Conversation } from '../types/api'

interface ReflectionListProps {
  reflections: Conversation[]
  activeId: number | null
  onSelect: (id: number) => void
  onDelete: (id: number) => Promise<void>
  isDeleting?: boolean
}

export default function ReflectionList({ reflections, activeId, onSelect, onDelete, isDeleting = false }: ReflectionListProps) {
  if (!reflections.length) {
    return (
      <p className="rounded-soft border border-dashed border-clay-200 bg-white/70 p-4 text-sm leading-relaxed text-ink-700">
        No reflections yet. Start your first reflection above.
      </p>
    )
  }

  return (
    <ul className="space-y-2.5">
      {reflections.map((reflection) => {
        const isActive = reflection.id === activeId
        return (
          <li key={reflection.id}>
            <div
              className={`group flex items-center gap-2 rounded-soft border px-3 py-2.5 transition ${
                isActive
                  ? 'border-clay-300 bg-clay-100 text-ink-900 shadow-[0_10px_24px_-22px_rgba(63,54,47,0.72)]'
                  : 'border-transparent bg-white/72 text-ink-800 hover:border-clay-200 hover:bg-white'
              }`}
            >
              <button type="button" onClick={() => onSelect(reflection.id)} className="min-w-0 flex-1 text-left">
                <p className="truncate text-sm font-semibold">{reflection.title}</p>
                <p className="text-xs text-ink-700/70">{new Date(reflection.created_at).toLocaleDateString()}</p>
              </button>
              <button
                type="button"
                onClick={() => {
                  void onDelete(reflection.id)
                }}
                disabled={isDeleting}
                className="rounded-full border border-clay-200/70 bg-white px-2.5 py-1 text-[11px] font-semibold text-ink-700 opacity-100 transition hover:border-clay-300 hover:text-ink-900 md:opacity-0 md:group-hover:opacity-100 disabled:cursor-not-allowed disabled:opacity-60"
                aria-label="Delete reflection"
              >
                {isDeleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </li>
        )
      })}
    </ul>
  )
}
