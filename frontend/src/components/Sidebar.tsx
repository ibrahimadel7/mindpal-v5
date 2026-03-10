import { NavLink } from 'react-router-dom'
import ReflectionList from './ReflectionList'
import { useAppState } from '../state/useAppState'

interface SidebarProps {
  className?: string
  onNavigate?: () => void
  onClose?: () => void
}

export default function Sidebar({ className = '', onNavigate, onClose }: SidebarProps) {
  const { conversations, currentConversationId, createConversation, removeConversation, selectConversation, isDeleting } =
    useAppState()

  return (
    <aside
      className={`h-full shrink-0 border-r border-clay-200/75 bg-[#f7f4ef] px-5 py-5 shadow-[10px_0_38px_-35px_rgba(62,49,38,0.5)] ${className}`}
    >
      <div className="flex h-full min-h-0 flex-col gap-5">
        <div className="flex items-center justify-between gap-3 rounded-soft bg-white/70 px-3 py-3">
          <div className="flex items-center gap-3">
            <img src="/logo.svg" alt="MindPal" className="h-9 w-9 rounded-full object-cover" />
            <div>
              <p className="text-xl font-semibold tracking-tight text-ink-900">MindPal</p>
              <p className="text-[11px] uppercase tracking-[0.16em] text-ink-700/75">Reflection Space</p>
            </div>
          </div>
          {onClose ? (
            <button
              type="button"
              onClick={onClose}
              aria-label="Close sidebar"
              className="subtle-icon-button"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                <path d="M6 6L18 18" strokeLinecap="round" />
                <path d="M6 18L18 6" strokeLinecap="round" />
              </svg>
            </button>
          ) : null}
        </div>

        <nav className="grid grid-cols-2 gap-2 rounded-soft bg-white p-1.5 shadow-soft md:grid-cols-1">
          <NavLink
            to="/chat"
            onClick={onNavigate}
            className={({ isActive }) =>
              `rounded-soft px-3 py-2 text-sm font-semibold transition ${
                isActive ? 'bg-clay-100 text-ink-900' : 'text-ink-700 hover:bg-sand-50/85'
              }`
            }
          >
            Chat
          </NavLink>
          <NavLink
            to="/insights"
            onClick={onNavigate}
            className={({ isActive }) =>
              `rounded-soft px-3 py-2 text-sm font-semibold transition ${
                isActive ? 'bg-clay-100 text-ink-900' : 'text-ink-700 hover:bg-sand-50/85'
              }`
            }
          >
            Insights
          </NavLink>
        </nav>

        <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-ink-700/65">Recent Entries</p>

        <button
          type="button"
          onClick={() => void createConversation()}
          disabled={isDeleting}
          className="rounded-soft bg-clay-200 px-4 py-3 text-left text-sm font-semibold text-ink-900 transition hover:bg-clay-300 disabled:cursor-not-allowed disabled:opacity-60"
        >
          + New Reflection
        </button>

        <div className="min-h-0 flex-1 overflow-auto pr-1">
          <ReflectionList
            reflections={conversations}
            activeId={currentConversationId}
            onSelect={(id) => void selectConversation(id)}
            onDelete={async (id) => {
              await removeConversation(id)
            }}
            isDeleting={isDeleting}
          />
        </div>

        <p className="pt-1 text-xs text-ink-700/70">Your emotional journal</p>
      </div>
    </aside>
  )
}
