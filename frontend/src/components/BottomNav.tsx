import { NavLink } from 'react-router-dom'

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

function MenuIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <path d="M4 7h16" strokeLinecap="round" />
      <path d="M4 12h16" strokeLinecap="round" />
      <path d="M4 17h16" strokeLinecap="round" />
    </svg>
  )
}

interface BottomNavProps {
  onOpenNavigation?: () => void
}

export default function BottomNav({ onOpenNavigation }: BottomNavProps) {
  const linkClass = ({ isActive }: { isActive: boolean }) =>
    `flex flex-1 flex-col items-center gap-1 py-2 text-xs font-semibold transition ${
      isActive ? 'text-ink-900' : 'text-ink-700/70'
    }`

  const indicatorClass = ({ isActive }: { isActive: boolean }) =>
    `flex flex-col items-center gap-1 rounded-soft px-4 py-1.5 transition ${
      isActive ? 'bg-clay-200 text-ink-900' : 'text-ink-700/70'
    }`

  return (
    <nav
      className="fixed bottom-0 inset-x-0 z-30 flex items-center justify-around border-t border-clay-200/80 bg-[#f3efe9] pb-safe lg:hidden"
      aria-label="Main navigation"
    >
      <NavLink to="/chat" className={linkClass}>
        {({ isActive }) => (
          <span className={indicatorClass({ isActive })}>
            <ChatIcon />
            <span>Chat</span>
          </span>
        )}
      </NavLink>
      <NavLink to="/insights" className={linkClass}>
        {({ isActive }) => (
          <span className={indicatorClass({ isActive })}>
            <InsightsIcon />
            <span>Insights</span>
          </span>
        )}
      </NavLink>
      <NavLink to="/recommendations" className={linkClass}>
        {({ isActive }) => (
          <span className={indicatorClass({ isActive })}>
            <RecommendationsIcon />
            <span>Plans</span>
          </span>
        )}
      </NavLink>
      {onOpenNavigation ? (
        <button type="button" onClick={onOpenNavigation} className={linkClass({ isActive: false })} aria-label="Open menu">
          <span className={indicatorClass({ isActive: false })}>
            <MenuIcon />
            <span>Menu</span>
          </span>
        </button>
      ) : null}
    </nav>
  )
}
