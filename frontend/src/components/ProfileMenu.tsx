import { useEffect, useRef, useState } from 'react'
import type { UserProfileSummary } from '../state/AppStateStore'

interface ProfileMenuProps {
  profile: UserProfileSummary
  isCollapsed?: boolean
}

function UserIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <path d="M20 21a8 8 0 0 0-16 0" strokeLinecap="round" />
      <circle cx="12" cy="8" r="4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function SettingsIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <circle cx="12" cy="12" r="3" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M19.4 15a1.7 1.7 0 0 0 .34 1.86l.06.06a2 2 0 0 1-1.42 3.42h-.08a1.7 1.7 0 0 0-1.6 1.1 2 2 0 0 1-1.9 1.3h-.12a2 2 0 0 1-1.8-1.1 1.7 1.7 0 0 0-1.52-.92H10a1.7 1.7 0 0 0-1.52.92 2 2 0 0 1-1.8 1.1h-.12a2 2 0 0 1-1.9-1.3 1.7 1.7 0 0 0-1.6-1.1h-.08a2 2 0 0 1-1.42-3.42l.06-.06A1.7 1.7 0 0 0 2.6 15a1.7 1.7 0 0 0-.34-1.86l-.06-.06A2 2 0 0 1 3.62 9.66h.08a1.7 1.7 0 0 0 1.6-1.1 2 2 0 0 1 1.9-1.3h.12a2 2 0 0 1 1.8 1.1 1.7 1.7 0 0 0 1.52.92h.04a1.7 1.7 0 0 0 1.52-.92 2 2 0 0 1 1.8-1.1h.12a2 2 0 0 1 1.9 1.3 1.7 1.7 0 0 0 1.6 1.1h.08a2 2 0 0 1 1.42 3.42l-.06.06A1.7 1.7 0 0 0 19.4 15Z" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function HelpIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <circle cx="12" cy="12" r="9" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M9.8 9a2.4 2.4 0 1 1 4.3 1.6c-.8.8-1.8 1.2-2.1 2.2v.7" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx="12" cy="17" r="1" fill="currentColor" stroke="none" />
    </svg>
  )
}

function LogoutIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
      <path d="M10 17l5-5-5-5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M15 12H3" strokeLinecap="round" />
      <path d="M14 5h4a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

function ChevronIcon({ isOpen }: { isOpen: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={`h-4 w-4 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`}
      fill="none"
      stroke="currentColor"
      strokeWidth="1.9"
      aria-hidden="true"
    >
      <path d="M6 9l6 6 6-6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export default function ProfileMenu({ profile, isCollapsed = false }: ProfileMenuProps) {
  const [isOpen, setIsOpen] = useState(false)
  const containerRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (!isOpen) {
      return
    }

    const handlePointerDown = (event: PointerEvent) => {
      if (!containerRef.current?.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsOpen(false)
      }
    }

    window.addEventListener('pointerdown', handlePointerDown)
    window.addEventListener('keydown', handleKeyDown)

    return () => {
      window.removeEventListener('pointerdown', handlePointerDown)
      window.removeEventListener('keydown', handleKeyDown)
    }
  }, [isOpen])

  const handleAction = () => {
    setIsOpen(false)
  }

  const triggerClasses = isCollapsed
    ? 'group flex h-10 w-10 items-center justify-center rounded-full border border-clay-200/85 bg-white/90 text-ink-900 shadow-soft transition hover:border-clay-300 hover:bg-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-clay-300 focus-visible:ring-offset-2 focus-visible:ring-offset-[#f3efe9]'
    : 'group flex w-full items-center gap-2.5 rounded-[1rem] border border-clay-200/85 bg-white/78 px-3 py-2.5 text-left text-ink-800 shadow-soft transition hover:border-clay-300 hover:bg-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-clay-300 focus-visible:ring-offset-2 focus-visible:ring-offset-[#f3efe9]'

  return (
    <div ref={containerRef} className="relative w-full">
      <button
        type="button"
        onClick={() => setIsOpen((current) => !current)}
        aria-haspopup="menu"
        aria-expanded={isOpen}
        aria-label={isCollapsed ? `${profile.displayName} account menu` : `${profile.displayName}, ${profile.planLabel} account menu`}
        className={triggerClasses}
      >
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-ink-900 text-sm font-semibold tracking-[0.08em] text-white shadow-[0_10px_22px_-16px_rgba(38,31,25,0.95)]">
          {profile.initials}
        </span>

        {!isCollapsed ? (
          <span className="min-w-0 flex-1">
            <span className="block truncate text-[15px] font-semibold text-ink-900">{profile.displayName}</span>
            <span className="block text-[10px] uppercase tracking-[0.16em] text-ink-700/70">{profile.planLabel}</span>
          </span>
        ) : null}

        {!isCollapsed ? (
          <span className="ml-auto inline-flex h-7 w-7 items-center justify-center rounded-full border border-clay-200 bg-sand-50 text-ink-700 transition hover:border-clay-300">
            <ChevronIcon isOpen={isOpen} />
          </span>
        ) : null}
      </button>

      {isOpen ? (
        <div
          className={`absolute bottom-full z-30 mb-2.5 animate-rise rounded-[1.2rem] border border-clay-200/90 bg-[#fbf8f3] p-2.5 shadow-[0_30px_70px_-34px_rgba(63,54,47,0.55)] ${
            isCollapsed ? 'left-0 w-[16.5rem]' : 'left-0 w-[17.5rem]'
          }`}
          role="menu"
          aria-label="Profile menu"
        >
          <div className="flex items-center gap-2.5 rounded-[0.95rem] border border-clay-200/70 bg-white/85 px-2.5 py-2.5">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-ink-900 text-sm font-semibold tracking-[0.08em] text-white">
              {profile.initials}
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[13px] font-semibold text-ink-900">{profile.displayName}</p>
              <p className="text-[11px] text-ink-700/70">MindPal account</p>
            </div>
            <span className="rounded-full bg-clay-100 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.14em] text-ink-700">
              {profile.planLabel}
            </span>
          </div>

          <div className="mt-2.5 space-y-1">
            <button
              type="button"
              onClick={handleAction}
              className="flex w-full items-center gap-2.5 rounded-[0.85rem] px-2.5 py-2 text-left text-[13px] font-semibold text-ink-800 transition hover:bg-sand-100/90 hover:text-ink-900"
              role="menuitem"
            >
              <UserIcon />
              <span>Profile</span>
            </button>
            <button
              type="button"
              onClick={handleAction}
              className="flex w-full items-center gap-2.5 rounded-[0.85rem] px-2.5 py-2 text-left text-[13px] font-semibold text-ink-800 transition hover:bg-sand-100/90 hover:text-ink-900"
              role="menuitem"
            >
              <SettingsIcon />
              <span>Settings</span>
            </button>
            <button
              type="button"
              onClick={handleAction}
              className="flex w-full items-center gap-2.5 rounded-[0.85rem] px-2.5 py-2 text-left text-[13px] font-semibold text-ink-800 transition hover:bg-sand-100/90 hover:text-ink-900"
              role="menuitem"
            >
              <HelpIcon />
              <span>Help</span>
            </button>
            <div className="my-1 h-px bg-clay-200/80" />
            <button
              type="button"
              onClick={handleAction}
              className="flex w-full items-center gap-2.5 rounded-[0.85rem] px-2.5 py-2 text-left text-[13px] font-semibold text-ink-800 transition hover:bg-sand-100/90 hover:text-ink-900"
              role="menuitem"
            >
              <LogoutIcon />
              <span>Log out</span>
            </button>
          </div>
        </div>
      ) : null}
    </div>
  )
}