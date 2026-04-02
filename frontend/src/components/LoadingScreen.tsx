import { useEffect, useRef, useState } from 'react'

type LoadingVariant = 'chat' | 'insights' | 'recommendations' | 'initial'

interface LoadingScreenProps {
  isVisible: boolean
  variant?: LoadingVariant
}

const SHOW_DELAY_MS = 120
const MIN_VISIBLE_MS = 180
const FADE_DURATION_MS = 260

function Spinner() {
  return (
    <div className="relative inline-block">
      <div className="h-8 w-8 rounded-full border-2 border-clay-200/70 border-t-ink-900/70 animate-spin" />
    </div>
  )
}

export default function LoadingScreen({ isVisible, variant = 'chat' }: LoadingScreenProps) {
  const [shouldRender, setShouldRender] = useState(false)
  const [isActive, setIsActive] = useState(false)
  const shownAtRef = useRef<number>(0)
  const showTimerRef = useRef<number | null>(null)
  const hideTimerRef = useRef<number | null>(null)
  const unmountTimerRef = useRef<number | null>(null)

  useEffect(() => {
    return () => {
      if (showTimerRef.current) window.clearTimeout(showTimerRef.current)
      if (hideTimerRef.current) window.clearTimeout(hideTimerRef.current)
      if (unmountTimerRef.current) window.clearTimeout(unmountTimerRef.current)
    }
  }, [])

  useEffect(() => {
    if (showTimerRef.current) window.clearTimeout(showTimerRef.current)
    if (hideTimerRef.current) window.clearTimeout(hideTimerRef.current)
    if (unmountTimerRef.current) window.clearTimeout(unmountTimerRef.current)

    if (isVisible) {
      showTimerRef.current = window.setTimeout(() => {
        shownAtRef.current = Date.now()
        setShouldRender(true)
        window.requestAnimationFrame(() => setIsActive(true))
      }, SHOW_DELAY_MS)
      return
    }

    if (!shouldRender) {
      return
    }

    const elapsed = Date.now() - shownAtRef.current
    const holdFor = Math.max(0, MIN_VISIBLE_MS - elapsed)

    hideTimerRef.current = window.setTimeout(() => {
      setIsActive(false)
      unmountTimerRef.current = window.setTimeout(() => {
        setShouldRender(false)
      }, FADE_DURATION_MS)
    }, holdFor)
  }, [isVisible, shouldRender])

  if (!shouldRender) return null

  const loadingLabel =
    variant === 'initial'
      ? 'Preparing MindPal...'
      : variant === 'insights'
      ? 'Loading insights...'
      : variant === 'recommendations'
        ? 'Loading recommendations...'
        : 'Loading your reflection...'

  return (
    <div
      className={`fixed inset-0 z-50 flex flex-col items-center justify-center bg-sand-50/50 backdrop-blur-[1px] transition-opacity duration-200 ${
        isActive ? 'opacity-100' : 'opacity-0'
      }`}
      style={{ transitionDuration: `${FADE_DURATION_MS}ms` }}
    >
      <div className="relative z-10 flex flex-col items-center gap-2 text-center">
        <Spinner />
        <p className="text-xs font-medium tracking-[0.08em] text-ink-700/75">{loadingLabel}</p>
      </div>
    </div>
  )
}
