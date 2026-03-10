import { NavLink } from 'react-router-dom'
import ReflectionList from './ReflectionList'
import { useAppState } from '../state/useAppState'

export default function Sidebar() {
  const { conversations, currentConversationId, createConversation, removeConversation, selectConversation } = useAppState()

  return (
    <aside className="w-full shrink-0 border-b border-clay-100 bg-sand-100/80 px-4 py-5 md:h-screen md:w-[260px] md:border-b-0 md:border-r">
      <div className="flex h-full flex-col gap-5">
        <div>
          <p className="font-heading text-3xl leading-none text-ink-900">MindPal</p>
          <p className="mt-1 text-xs uppercase tracking-[0.16em] text-ink-700/75">Reflective Companion</p>
        </div>

        <nav className="grid grid-cols-2 gap-2 rounded-soft bg-white/80 p-1 md:grid-cols-1">
          <NavLink
            to="/chat"
            className={({ isActive }) =>
              `rounded-soft px-3 py-2 text-sm font-semibold transition ${
                isActive ? 'bg-clay-100 text-ink-900' : 'text-ink-700 hover:bg-sand-50'
              }`
            }
          >
            Chat
          </NavLink>
          <NavLink
            to="/insights"
            className={({ isActive }) =>
              `rounded-soft px-3 py-2 text-sm font-semibold transition ${
                isActive ? 'bg-clay-100 text-ink-900' : 'text-ink-700 hover:bg-sand-50'
              }`
            }
          >
            Insights
          </NavLink>
        </nav>

        <button
          type="button"
          onClick={() => void createConversation()}
          className="rounded-soft bg-clay-200 px-4 py-2.5 text-left text-sm font-semibold text-ink-900 transition hover:bg-clay-300"
        >
          + New Reflection
        </button>

        <div className="min-h-0 flex-1 overflow-auto pr-1">
          <ReflectionList
            reflections={conversations}
            activeId={currentConversationId}
            onSelect={(id) => void selectConversation(id)}
            onDelete={(id) => void removeConversation(id)}
          />
        </div>

        <p className="pt-1 text-xs text-ink-700/70">Your emotional journal</p>
      </div>
    </aside>
  )
}
