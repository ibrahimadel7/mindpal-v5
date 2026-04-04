import { useEffect, useMemo } from 'react'
import { useAppState } from '../state/useAppState'

interface ChatInsightsRailProps {
  className?: string
  onClose?: () => void
}

type MoodLevel = 'Balanced' | 'Uplifted' | 'Tender' | 'Heavy'

const emotionWeights: Record<string, number> = {
  joy: 1,
  excitement: 0.8,
  gratitude: 0.9,
  calm: 0.45,
  neutral: 0,
  anxiety: -0.65,
  fear: -0.75,
  frustration: -0.55,
  sadness: -0.9,
  anger: -0.8,
}

function toMoodLevel(score: number): MoodLevel {
  if (score >= 0.38) {
    return 'Uplifted'
  }
  if (score >= 0.08) {
    return 'Balanced'
  }
  if (score >= -0.24) {
    return 'Tender'
  }
  return 'Heavy'
}

function normalizeEmotionLabel(label: string): string {
  return label.trim().toLowerCase()
}

export default function ChatInsightsRail({ className = '', onClose }: ChatInsightsRailProps) {
  const { insights, isLoadingInsights, fetchInsights, conversations, messagesByConversation } = useAppState()

  useEffect(() => {
    if (!insights.emotions.length && !insights.timePatterns.length) {
      void fetchInsights()
    }
  }, [fetchInsights, insights.emotions.length, insights.timePatterns.length])

  const moodSummary = useMemo(() => {
    if (!insights.emotions.length) {
      return { mood: 'Balanced' as MoodLevel, entryCount: 0 }
    }

    const totals = insights.emotions.reduce(
      (acc, item) => {
        const normalized = normalizeEmotionLabel(item.label)
        const weight = emotionWeights[normalized] ?? 0
        acc.weighted += weight * item.count
        acc.entries += item.count
        return acc
      },
      { weighted: 0, entries: 0 },
    )

    const score = totals.entries ? totals.weighted / totals.entries : 0
    return { mood: toMoodLevel(score), entryCount: totals.entries }
  }, [insights.emotions])

  const streak = useMemo(() => {
    const allTimestamps = Object.values(messagesByConversation)
      .flat()
      .map((message) => message.timestamp)

    const seedTimestamps = allTimestamps.length ? allTimestamps : conversations.map((conversation) => conversation.created_at)

    if (!seedTimestamps.length) {
      return 0
    }

    const uniqueDays = Array.from(
      new Set(
        seedTimestamps.map((stamp) => {
          const date = new Date(stamp)
          return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime()
        }),
      ),
    ).sort((a, b) => b - a)

    let current = 1
    for (let index = 1; index < uniqueDays.length; index += 1) {
      const previousDay = uniqueDays[index - 1]
      const nextDay = uniqueDays[index]
      const diff = Math.round((previousDay - nextDay) / (1000 * 60 * 60 * 24))
      if (diff === 1) {
        current += 1
        continue
      }
      break
    }

    return current
  }, [conversations, messagesByConversation])

  return (
    <aside
      className={`h-full shrink-0 border-l border-clay-200/70 bg-[#f5f1ea] px-4 py-5 shadow-[-10px_0_38px_-35px_rgba(62,49,38,0.5)] ${className}`}
    >
      <div className="flex h-full min-h-0 flex-col gap-5">
        <div className="flex items-center justify-between">
          <p className="text-sm font-semibold uppercase tracking-[0.14em] text-ink-700">Today</p>
          {onClose ? (
            <button
              type="button"
              onClick={onClose}
              aria-label="Close insights sidebar"
              className="subtle-icon-button"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                <path d="M6 6L18 18" strokeLinecap="round" />
                <path d="M6 18L18 6" strokeLinecap="round" />
              </svg>
            </button>
          ) : null}
        </div>

        <section>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-ink-700/70">Today's Mood Map</p>
          <article className="mt-3 rounded-panel border border-clay-200/80 bg-clay-100/80 px-5 py-6">
            <p className="text-[2rem] font-semibold leading-none text-clay-400">{moodSummary.mood}</p>
            <p className="mt-1 text-xs uppercase tracking-[0.08em] text-ink-700/75">
              Based on {moodSummary.entryCount} insight entries today
            </p>
            {isLoadingInsights ? <p className="mt-2 text-xs text-ink-700/70">Refreshing mood map...</p> : null}
          </article>
        </section>

        <article className="rounded-panel bg-[#1d1814] px-5 py-6 text-center text-sand-50 shadow-soft">
          <p className="text-[2rem] leading-none">{streak}</p>
          <p className="mt-1 text-lg font-semibold">Day Streak</p>
          <p className="mt-1 text-[11px] uppercase tracking-[0.12em] text-sand-100/70">You're doing great</p>
        </article>
      </div>
    </aside>
  )
}
