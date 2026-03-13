import { NavLink } from 'react-router-dom'
import ReflectionList from './ReflectionList'
import { useAppState } from '../state/useAppState'

interface SidebarProps {
  className?: string
  onNavigate?: () => void
  onClose?: () => void
  isCollapsed?: boolean
  onToggleCollapse?: () => void
  hideNav?: boolean
}

function ChatIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function InsightsIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <line x1="18" y1="20" x2="18" y2="10" strokeLinecap="round" />
      <line x1="12" y1="20" x2="12" y2="4" strokeLinecap="round" />
      <line x1="6" y1="20" x2="6" y2="14" strokeLinecap="round" />
    </svg>
  )
}

function RecommendationsIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <path d="M9 21h6" strokeLinecap="round" />
      <path d="M12 3a6 6 0 0 1 6 6c0 2.2-1.2 4.2-3 5.4V17H9v-2.6C7.2 13.2 6 11.2 6 9a6 6 0 0 1 6-6z" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export default function Sidebar({ className = '', onNavigate, onClose, isCollapsed = false, onToggleCollapse, hideNav = false }: SidebarProps) {
  const { conversations, currentConversationId, createConversation, removeConversation, selectConversation, isDeleting } =
    useAppState()

  const navLinkClass = ({ isActive }: { isActive: boolean }) =>
    `rounded-soft px-3 py-2 text-sm font-semibold transition ${
      isActive ? 'bg-clay-200 text-ink-900' : 'text-ink-700 hover:bg-sand-50/90'
    }`

  const collapsedNavLinkClass = ({ isActive }: { isActive: boolean }) =>
    `flex h-10 w-10 items-center justify-center rounded-soft transition ${
      isActive ? 'bg-clay-200 text-ink-900' : 'text-ink-700 hover:bg-sand-50/90'
    }`

  if (isCollapsed) {
    return (
      <aside
        className={`h-full shrink-0 overflow-hidden border-r border-clay-200/80 bg-[#f3efe9] shadow-[10px_0_38px_-35px_rgba(62,49,38,0.5)] transition-[width] duration-200 ease-in-out w-16 ${className}`}
      >
        <div className="flex h-full flex-col items-center gap-3 py-4">
          <button
            type="button"
            onClick={onToggleCollapse}
            title="Expand sidebar"
            aria-label="Expand sidebar"
            className="flex h-10 w-10 items-center justify-center rounded-full transition hover:bg-clay-200/60"
          >
            <img src="/logo.svg" alt="MindPal" className="h-8 w-8 rounded-full object-cover" />
          </button>

          <div className="mt-2 flex flex-col items-center gap-1">
            <NavLink to="/chat" onClick={onNavigate} title="Chat" className={collapsedNavLinkClass}>
              <ChatIcon />
            </NavLink>
            <NavLink to="/insights" onClick={onNavigate} title="Insights" className={collapsedNavLinkClass}>
              <InsightsIcon />
            </NavLink>
            <NavLink to="/recommendations" onClick={onNavigate} title="Recommendations" className={collapsedNavLinkClass}>
              <RecommendationsIcon />
            </NavLink>
          </div>
        </div>
      </aside>
    )
  }

  return (
    <aside
      className={`h-full shrink-0 overflow-hidden border-r border-clay-200/80 bg-[#f3efe9] px-5 py-5 shadow-[10px_0_38px_-35px_rgba(62,49,38,0.5)] transition-[width] duration-200 ease-in-out w-[344px] ${className}`}
    >
      <div className="flex h-full min-h-0 flex-col gap-5">
        <div className="flex items-center justify-between gap-3 rounded-[1.15rem] bg-white/80 px-3 py-3">
          <div className="flex items-center gap-3">
            <img src="/logo.svg" alt="MindPal" className="h-9 w-9 rounded-full object-cover" />
            <div>
              <p className="text-xl font-semibold tracking-tight text-ink-900">MindPal</p>
              <p className="text-[11px] uppercase tracking-[0.16em] text-ink-700/75">Insights Dashboard</p>
            </div>
          </div>
          {onToggleCollapse ? (
            <button
              type="button"
              onClick={onToggleCollapse}
              aria-label="Collapse sidebar"
              className="subtle-icon-button"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                <path d="M15 18l-6-6 6-6" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          ) : onClose ? (
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

        {!hideNav && (
          <nav className="grid grid-cols-2 gap-2 rounded-[1.1rem] bg-white/95 p-1.5 shadow-soft md:grid-cols-1">
            <NavLink to="/chat" onClick={onNavigate} className={navLinkClass}>
              Chat
            </NavLink>
            <NavLink to="/insights" onClick={onNavigate} className={navLinkClass}>
              Insights
            </NavLink>
            <NavLink to="/recommendations" onClick={onNavigate} className={navLinkClass}>
              Recommendations
            </NavLink>
          </nav>
        )}

        <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-ink-700/65">Recent Entries</p>

        <button
          type="button"
          onClick={() => void createConversation()}
          disabled={isDeleting}
          className="rounded-[1rem] bg-clay-200 px-4 py-3 text-left text-sm font-semibold text-ink-900 transition hover:bg-clay-300 disabled:cursor-not-allowed disabled:opacity-60"
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
