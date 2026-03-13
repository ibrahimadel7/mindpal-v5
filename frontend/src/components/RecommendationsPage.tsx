import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  adoptRecommendationItem,
  completeRecommendationItem,
  createHabit,
  deleteHabit,
  generateRecommendations,
  getHabitChecklist,
  getRecommendationHistory,
  getTodayRecommendations,
  logRecommendationItemInteraction,
  selectRecommendationItem,
  setHabitCheck,
} from '../services/api'
import { useAppState } from '../state/useAppState'
import type {
  DailyHabitChecklistItem,
  DailyHabitChecklistResponse,
  RecommendationBatch,
  RecommendationCategory,
  RecommendationItem,
} from '../types/api'

interface RecommendationsPageProps {
  onOpenNavigation?: () => void
}

const categories: Array<{ value: RecommendationCategory; label: string }> = [
  { value: 'balance', label: 'Balance' },
  { value: 'calm', label: 'Calm' },
  { value: 'focus', label: 'Focus' },
  { value: 'energy', label: 'Energy' },
  { value: 'reflection', label: 'Reflection' },
]

function formatDate(value: string) {
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return value
  return parsed.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

function formatKind(kind: string) {
  return kind.replaceAll('_', ' ')
}

function formatDuration(minutes: number | null) {
  if (!minutes) return 'Flexible'
  return `${minutes} min`
}

interface CategorySelectorProps {
  selectedCategory: RecommendationCategory
  onSelect: (category: RecommendationCategory) => void
}

function CategorySelector({ selectedCategory, onSelect }: CategorySelectorProps) {
  return (
    <div className="flex flex-wrap gap-2">
      {categories.map((category) => {
        const isSelected = category.value === selectedCategory
        return (
          <button
            key={category.value}
            type="button"
            onClick={() => onSelect(category.value)}
            className={`rounded-full border px-4 py-2 text-sm font-semibold transition ${
              isSelected
                ? 'border-ink-900 bg-ink-900 text-white'
                : 'border-clay-200 bg-white text-ink-800 hover:bg-sand-100'
            }`}
          >
            {category.label}
          </button>
        )
      })}
    </div>
  )
}

interface RecommendationItemCardProps {
  item: RecommendationItem
  isBusy: boolean
  isTimerRunning: boolean
  timerRemaining: number | null
  isExpanded: boolean
  onToggleExpanded: () => void
  onSelect: (item: RecommendationItem) => Promise<void>
  onComplete: (item: RecommendationItem) => Promise<void>
  onAdoptHabit: (item: RecommendationItem) => Promise<void>
  onStartTimer: (item: RecommendationItem) => Promise<void>
}

function RecommendationItemCard({
  item,
  isBusy,
  isTimerRunning,
  timerRemaining,
  isExpanded,
  onToggleExpanded,
  onSelect,
  onComplete,
  onAdoptHabit,
  onStartTimer,
}: RecommendationItemCardProps) {
  const [isMoreOpen, setIsMoreOpen] = useState(false)

  const isCompleted = item.status === 'completed'
  const primaryDisabled = isBusy || isCompleted

  let primaryLabel = 'Select'
  let primaryAction = () => onSelect(item)
  if (item.kind === 'reflection') {
    primaryLabel = 'Open in chat'
    primaryAction = () => onSelect(item)
  } else if (item.kind === 'timed_action') {
    primaryLabel = isTimerRunning && timerRemaining !== null ? `Timer ${timerRemaining}s` : 'Start timer'
    primaryAction = () => onStartTimer(item)
  } else if (item.kind === 'habit') {
    primaryLabel = 'Add to habits'
    primaryAction = () => onAdoptHabit(item)
  } else {
    primaryLabel = 'Mark complete'
    primaryAction = () => onComplete(item)
  }

  return (
    <article className="rounded-[1.35rem] border border-clay-200/80 bg-sand-50/75 p-4 sm:p-5">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-full bg-white px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-700">
              {formatKind(item.kind)}
            </span>
            <span className="rounded-full bg-clay-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-700">
              {formatDuration(item.estimated_duration_minutes)}
            </span>
            <span className="rounded-full bg-clay-200 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-900">
              {item.status}
            </span>
          </div>
          <h3 className="mt-3 text-lg font-semibold text-ink-900 sm:text-xl">{item.title}</h3>

          {isExpanded ? (
            <div className="mt-3 space-y-3">
              <p className="text-sm leading-6 text-ink-700">{item.rationale}</p>
              {item.follow_up_text ? <p className="text-sm text-ink-700/78">{item.follow_up_text}</p> : null}
              {item.action_payload.prompt ? (
                <div className="rounded-[1rem] border border-clay-200/70 bg-white/85 px-3 py-3 text-sm text-ink-800">
                  {String(item.action_payload.prompt)}
                </div>
              ) : null}
            </div>
          ) : (
            <p className="mt-2 line-clamp-2 text-sm leading-6 text-ink-700">{item.rationale}</p>
          )}
        </div>

        <div className="flex w-full flex-col gap-2 sm:w-auto sm:min-w-[200px] sm:items-end">
          <button
            type="button"
            onClick={() => void primaryAction()}
            disabled={item.kind === 'timed_action' ? isBusy || isTimerRunning || isCompleted : primaryDisabled}
            className="rounded-full bg-ink-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-ink-800 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {primaryLabel}
          </button>

          <div className="flex flex-wrap gap-2 sm:justify-end">
            <button
              type="button"
              onClick={onToggleExpanded}
              className="rounded-full border border-clay-300 px-3 py-1.5 text-xs font-semibold text-ink-800 transition hover:bg-white"
            >
              {isExpanded ? 'Hide details' : 'Show details'}
            </button>
            <button
              type="button"
              onClick={() => setIsMoreOpen((current) => !current)}
              className="rounded-full border border-clay-300 px-3 py-1.5 text-xs font-semibold text-ink-800 transition hover:bg-white"
            >
              {isMoreOpen ? 'Less' : 'More'}
            </button>
          </div>

          {isMoreOpen ? (
            <div className="w-full space-y-2 rounded-[1rem] border border-clay-200/80 bg-white/85 p-2 sm:w-[220px]">
              {item.kind !== 'reflection' && !(item.kind === 'instant_action') ? (
                <button
                  type="button"
                  onClick={() => void onComplete(item)}
                  disabled={isBusy || isCompleted}
                  className="w-full rounded-lg border border-clay-300 px-3 py-2 text-left text-xs font-semibold text-ink-800 transition hover:bg-sand-50 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Mark complete
                </button>
              ) : null}

              {item.kind !== 'reflection' && !(item.kind === 'timed_action') && !(item.kind === 'habit') ? (
                <button
                  type="button"
                  onClick={() => void onSelect(item)}
                  disabled={isBusy || isCompleted}
                  className="w-full rounded-lg border border-clay-300 px-3 py-2 text-left text-xs font-semibold text-ink-800 transition hover:bg-sand-50 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Select
                </button>
              ) : null}

              {item.kind === 'timed_action' ? (
                <button
                  type="button"
                  onClick={() => void onSelect(item)}
                  disabled={isBusy || isCompleted}
                  className="w-full rounded-lg border border-clay-300 px-3 py-2 text-left text-xs font-semibold text-ink-800 transition hover:bg-sand-50 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Select without timer
                </button>
              ) : null}

              {item.kind === 'habit' ? (
                <button
                  type="button"
                  onClick={() => void onComplete(item)}
                  disabled={isBusy || isCompleted}
                  className="w-full rounded-lg border border-clay-300 px-3 py-2 text-left text-xs font-semibold text-ink-800 transition hover:bg-sand-50 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  Mark complete
                </button>
              ) : null}
            </div>
          ) : null}
        </div>
      </div>
    </article>
  )
}

interface HabitChecklistCardProps {
  checklist: DailyHabitChecklistResponse | null
  activeItemIds: number[]
  onToggleHabit: (item: DailyHabitChecklistItem) => Promise<void>
  onRemoveHabit: (item: DailyHabitChecklistItem) => Promise<void>
  onAddHabit: (name: string) => Promise<void>
  isAddingHabit: boolean
}

function HabitChecklistCard({
  checklist,
  activeItemIds,
  onToggleHabit,
  onRemoveHabit,
  onAddHabit,
  isAddingHabit,
}: HabitChecklistCardProps) {
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [newHabitName, setNewHabitName] = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const trimmed = newHabitName.trim()
    if (!trimmed) return
    await onAddHabit(trimmed)
    setNewHabitName('')
    setIsFormOpen(false)
  }

  return (
    <article className="rounded-[1.6rem] border border-clay-200/80 bg-white/95 p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/65">Checklist</p>
          <h2 className="mt-1 text-xl font-semibold text-ink-900">Today's habits</h2>
        </div>
        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-ink-700/65">{checklist?.habits.length ?? 0} active</p>
      </div>

      {checklist?.habits.length ? (
        <div className="mt-4 space-y-3">
          {checklist.habits.map((item) => {
            const isBusy = activeItemIds.includes(item.habit.id)
            return (
              <div key={item.habit.id} className="flex items-start gap-3 rounded-[1rem] border border-clay-200/70 bg-sand-50/70 px-3 py-3">
                <label className="flex min-w-0 flex-1 cursor-pointer items-start gap-3">
                  <input
                    type="checkbox"
                    checked={item.is_completed}
                    onChange={() => void onToggleHabit(item)}
                    disabled={isBusy}
                    className="mt-1 h-4 w-4 rounded border-clay-300 text-ink-900 focus:ring-clay-300"
                  />
                  <span className="min-w-0 flex-1">
                    <span className="block text-sm font-semibold text-ink-900">{item.habit.name}</span>
                  </span>
                </label>
                <button
                  type="button"
                  onClick={() => void onRemoveHabit(item)}
                  disabled={isBusy}
                  aria-label={`Remove ${item.habit.name}`}
                  className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-clay-200 bg-white text-ink-700 transition hover:border-clay-300 hover:text-ink-900 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                    <path d="M6 7h12" strokeLinecap="round" />
                    <path d="M9.5 7V5.75c0-.414.336-.75.75-.75h3.5c.414 0 .75.336.75.75V7" strokeLinecap="round" />
                    <path d="M8.5 10v6" strokeLinecap="round" />
                    <path d="M12 10v6" strokeLinecap="round" />
                    <path d="M15.5 10v6" strokeLinecap="round" />
                    <path d="M7.5 7l.6 10.109a1 1 0 0 0 .998.941h5.804a1 1 0 0 0 .998-.941L16.5 7" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </button>
              </div>
            )
          })}
        </div>
      ) : (
        <p className="mt-4 text-sm text-ink-700/72">Add a habit below or adopt one from your recommendations.</p>
      )}

      {isFormOpen ? (
        <form onSubmit={(e) => void handleSubmit(e)} className="mt-4 flex gap-2">
          <input
            type="text"
            value={newHabitName}
            onChange={(e) => setNewHabitName(e.target.value)}
            placeholder="e.g. Morning Walk"
            autoFocus
            maxLength={255}
            className="min-w-0 flex-1 rounded-full border border-clay-300 bg-white px-4 py-2 text-sm text-ink-900 placeholder:text-ink-700/45 focus:outline-none focus:ring-2 focus:ring-clay-300"
          />
          <button
            type="submit"
            disabled={isAddingHabit || !newHabitName.trim()}
            className="rounded-full bg-ink-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-ink-800 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isAddingHabit ? 'Adding...' : 'Add'}
          </button>
          <button
            type="button"
            onClick={() => { setIsFormOpen(false); setNewHabitName('') }}
            className="rounded-full border border-clay-200 px-3 py-2 text-sm font-semibold text-ink-700 transition hover:bg-sand-50"
          >
            Cancel
          </button>
        </form>
      ) : (
        <button
          type="button"
          onClick={() => setIsFormOpen(true)}
          className="mt-4 flex items-center gap-1.5 text-sm font-semibold text-ink-700 transition hover:text-ink-900"
        >
          <span className="text-base leading-none">+</span> Add habit
        </button>
      )}
    </article>
  )
}

interface RecentBatchesCardProps {
  history: RecommendationBatch[]
}

function RecentBatchesCard({ history }: RecentBatchesCardProps) {
  const preview = history.slice(0, 3)

  return (
    <article className="rounded-[1.6rem] border border-clay-200/80 bg-white/95 p-5 shadow-soft">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/65">History</p>
          <h2 className="mt-1 text-xl font-semibold text-ink-900">Recent batches</h2>
        </div>
        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-ink-700/65">{history.length} saved</p>
      </div>

      {preview.length ? (
        <div className="mt-4 space-y-3">
          {preview.map((entry) => (
            <article key={entry.id} className="rounded-[1rem] border border-clay-200/70 bg-sand-50/70 px-3 py-3">
              <div className="flex items-center justify-between gap-3">
                <p className="text-sm font-semibold capitalize text-ink-900">{entry.category}</p>
                <span className="text-xs text-ink-700/70">{formatDate(entry.created_at)}</span>
              </div>
              <p className="mt-2 text-xs leading-5 text-ink-700/75">{entry.items.slice(0, 1).map((item) => item.title).join('')}</p>
            </article>
          ))}
        </div>
      ) : (
        <p className="mt-4 text-sm text-ink-700/72">No recommendation batches have been generated yet.</p>
      )}
    </article>
  )
}

export default function RecommendationsPage({ onOpenNavigation }: RecommendationsPageProps) {
  const navigate = useNavigate()
  const { userId } = useAppState()
  const [selectedCategory, setSelectedCategory] = useState<RecommendationCategory>('balance')
  const [batch, setBatch] = useState<RecommendationBatch | null>(null)
  const [history, setHistory] = useState<RecommendationBatch[]>([])
  const [checklist, setChecklist] = useState<DailyHabitChecklistResponse | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isRegenerating, setIsRegenerating] = useState(false)
  const [activeItemIds, setActiveItemIds] = useState<number[]>([])
  const [isAddingHabit, setIsAddingHabit] = useState(false)
  const [timerItemId, setTimerItemId] = useState<number | null>(null)
  const [timerRemaining, setTimerRemaining] = useState<number | null>(null)
  const [expandedItemIds, setExpandedItemIds] = useState<number[]>([])

  const selectedTimerItem = useMemo(
    () => batch?.items.find((item) => item.id === timerItemId) ?? null,
    [batch, timerItemId],
  )

  useEffect(() => {
    if (timerItemId === null || timerRemaining === null || timerRemaining <= 0) {
      return
    }

    const timeout = window.setTimeout(() => {
      setTimerRemaining((current) => (current === null ? null : current - 1))
    }, 1000)

    return () => window.clearTimeout(timeout)
  }, [timerItemId, timerRemaining])

  useEffect(() => {
    if (timerItemId === null || timerRemaining !== 0) {
      return
    }

    const currentItemId = timerItemId
    setTimerItemId(null)
    setTimerRemaining(null)

    void (async () => {
      try {
        await logRecommendationItemInteraction(currentItemId, {
          user_id: userId,
          event_type: 'timer_completed',
          payload: {},
        })
        const updated = await completeRecommendationItem(currentItemId, userId)
        setBatch((current) => {
          if (!current) return current
          return {
            ...current,
            items: current.items.map((item) => (item.id === updated.id ? updated : item)),
          }
        })
      } catch {
        setPageError('The timer finished, but completion could not be recorded.')
      }
    })()
  }, [timerItemId, timerRemaining, userId])

  const loadPage = useCallback(async (category: RecommendationCategory) => {
    setIsLoading(true)
    setPageError(null)
    try {
      const [todayBatch, historyResponse, checklistResponse] = await Promise.all([
        getTodayRecommendations(userId, category),
        getRecommendationHistory(userId, 8),
        getHabitChecklist(userId),
      ])
      setBatch(todayBatch)
      setHistory(historyResponse.batches)
      setChecklist(checklistResponse)
    } catch {
      setPageError('Recommendations are unavailable right now.')
    } finally {
      setIsLoading(false)
    }
  }, [userId])

  useEffect(() => {
    void loadPage(selectedCategory)
  }, [loadPage, selectedCategory])

  async function handleRegenerate() {
    setIsRegenerating(true)
    setPageError(null)
    try {
      const nextBatch = await generateRecommendations({ user_id: userId, category: selectedCategory })
      const [historyResponse, checklistResponse] = await Promise.all([
        getRecommendationHistory(userId, 8),
        getHabitChecklist(userId),
      ])
      setBatch(nextBatch)
      setHistory(historyResponse.batches)
      setChecklist(checklistResponse)
    } catch {
      setPageError('A fresh batch could not be generated.')
    } finally {
      setIsRegenerating(false)
    }
  }

  async function runItemAction(
    itemId: number,
    action: () => Promise<void>,
    failureMessage = 'That recommendation action could not be completed.',
  ) {
    setActiveItemIds((current) => [...current, itemId])
    setPageError(null)
    try {
      await action()
    } catch {
      setPageError(failureMessage)
    } finally {
      setActiveItemIds((current) => current.filter((value) => value !== itemId))
    }
  }

  async function handleSelect(item: RecommendationItem) {
    await runItemAction(item.id, async () => {
      const updated = await selectRecommendationItem(item.id, userId)
      setBatch((current) => {
        if (!current) return current
        return {
          ...current,
          items: current.items.map((entry) => (entry.id === updated.id ? updated : entry)),
        }
      })

      if (item.kind === 'reflection') {
        await logRecommendationItemInteraction(item.id, {
          user_id: userId,
          event_type: 'opened_chat_from_recommendation',
          payload: { prompt: item.action_payload.prompt ?? item.follow_up_text ?? '' },
        })
        navigate('/chat')
      }
    })
  }

  async function handleComplete(item: RecommendationItem) {
    await runItemAction(item.id, async () => {
      const updated = await completeRecommendationItem(item.id, userId)
      setBatch((current) => {
        if (!current) return current
        return {
          ...current,
          items: current.items.map((entry) => (entry.id === updated.id ? updated : entry)),
        }
      })
    })
  }

  async function handleAdoptHabit(item: RecommendationItem) {
    await runItemAction(item.id, async () => {
      await adoptRecommendationItem(item.id, { user_id: userId })
      const checklistResponse = await getHabitChecklist(userId)
      setChecklist(checklistResponse)
    })
  }

  async function handleAddHabit(name: string) {
    setIsAddingHabit(true)
    setPageError(null)
    try {
      await createHabit({ user_id: userId, name })
      const checklistResponse = await getHabitChecklist(userId)
      setChecklist(checklistResponse)
    } catch {
      setPageError('The habit could not be added. Please try again.')
    } finally {
      setIsAddingHabit(false)
    }
  }

  async function handleToggleHabit(item: DailyHabitChecklistItem) {
    await runItemAction(item.habit.id, async () => {
      const updated = await setHabitCheck(item.habit.id, {
        user_id: userId,
        date: checklist?.date,
        completed: !item.is_completed,
      })
      setChecklist((current) => {
        if (!current) return current
        return {
          ...current,
          habits: current.habits.map((entry) => (entry.habit.id === updated.habit.id ? updated : entry)),
        }
      })
    })
  }

  async function handleRemoveHabit(item: DailyHabitChecklistItem) {
    const confirmed = window.confirm(`Remove "${item.habit.name}" from today's habit checklist?`)
    if (!confirmed) {
      return
    }

    await runItemAction(
      item.habit.id,
      async () => {
        await deleteHabit(item.habit.id, userId)
        const checklistResponse = await getHabitChecklist(userId)
        setChecklist(checklistResponse)
      },
      'The habit could not be removed. Please try again.',
    )
  }

  async function handleStartTimer(item: RecommendationItem) {
    await runItemAction(item.id, async () => {
      const seconds = Number(item.action_payload.timer_seconds ?? (item.estimated_duration_minutes ?? 8) * 60)
      await logRecommendationItemInteraction(item.id, {
        user_id: userId,
        event_type: 'timer_started',
        payload: { timer_seconds: seconds },
      })
      setTimerItemId(item.id)
      setTimerRemaining(seconds)
    })
  }

  const completionRatio = useMemo(() => {
    if (!checklist?.habits.length) return 0
    const doneCount = checklist.habits.filter((item) => item.is_completed).length
    return Math.round((doneCount / checklist.habits.length) * 100)
  }, [checklist])

  function toggleItemExpansion(itemId: number) {
    setExpandedItemIds((current) =>
      current.includes(itemId) ? current.filter((value) => value !== itemId) : [...current, itemId],
    )
  }

  return (
    <section className="h-full overflow-y-auto px-4 py-5 sm:px-6 sm:py-6 lg:px-8">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-6">
        <header className="rounded-[2rem] border border-clay-200/80 bg-[linear-gradient(135deg,rgba(255,252,246,0.98),rgba(240,232,221,0.95))] p-6 shadow-soft sm:p-7">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div className="max-w-2xl">
              {onOpenNavigation ? (
                <button
                  type="button"
                  onClick={onOpenNavigation}
                  className="subtle-icon-button mb-4"
                  aria-label="Open sidebar"
                >
                  <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                    <path d="M4 7h16" strokeLinecap="round" />
                    <path d="M4 12h16" strokeLinecap="round" />
                    <path d="M4 17h16" strokeLinecap="round" />
                  </svg>
                </button>
              ) : null}
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-ink-700/65">Recommendations</p>
              <h1 className="mt-2 font-heading text-3xl text-ink-900 sm:text-4xl">Today's Recommendations</h1>
              <p className="mt-3 max-w-xl text-sm leading-6 text-ink-700">Choose one direction, then act on one item at a time.</p>
            </div>

            <div className="min-w-[250px] rounded-[1.6rem] border border-clay-200/80 bg-white/85 p-4">
              <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/65">Daily Progress</p>
              <p className="mt-2 text-3xl font-semibold text-ink-900">{completionRatio}%</p>
              <p className="mt-1 text-sm text-ink-700">Habits completed today</p>
              <div className="mt-4 h-2 rounded-full bg-clay-100">
                <div className="h-2 rounded-full bg-clay-300 transition-all" style={{ width: `${completionRatio}%` }} />
              </div>
            </div>
          </div>
        </header>

        <HabitChecklistCard
          checklist={checklist}
          activeItemIds={activeItemIds}
          onToggleHabit={handleToggleHabit}
          onRemoveHabit={handleRemoveHabit}
          onAddHabit={handleAddHabit}
          isAddingHabit={isAddingHabit}
        />

        <article className="rounded-[1.7rem] border border-clay-200/80 bg-white/95 p-5 shadow-soft sm:p-6">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-2xl font-semibold text-ink-900">Pick your direction</h2>
              <p className="mt-1 text-sm text-ink-700">Keep one category active and focus on one recommendation at a time.</p>
            </div>
            <button
              type="button"
              onClick={() => void handleRegenerate()}
              disabled={isRegenerating}
              className="rounded-full bg-ink-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-ink-800 disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isRegenerating ? 'Refreshing...' : 'Refresh batch'}
            </button>
          </div>

          <div className="mt-5">
            <CategorySelector selectedCategory={selectedCategory} onSelect={setSelectedCategory} />
          </div>
        </article>

        {pageError ? <p className="rounded-soft border border-clay-200 bg-clay-100 px-4 py-3 text-sm text-ink-800">{pageError}</p> : null}
        {isLoading ? <p className="text-sm text-ink-700/75">Loading recommendations...</p> : null}

        {batch ? (
          <article className="rounded-[1.7rem] border border-clay-200/80 bg-white/95 p-5 shadow-soft sm:p-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/65">Active Batch</p>
                <h2 className="mt-1 text-2xl font-semibold capitalize text-ink-900">{batch.category} recommendations</h2>
              </div>
              <p className="rounded-full bg-clay-100 px-3 py-1 text-xs font-semibold text-ink-700">{formatDate(batch.created_at)}</p>
            </div>

            <div className="mt-5 space-y-4">
              {batch.items.map((item) => {
                const isBusy = activeItemIds.includes(item.id)
                const isTimerRunning = timerItemId === item.id
                return (
                  <RecommendationItemCard
                    key={item.id}
                    item={item}
                    isBusy={isBusy}
                    isTimerRunning={isTimerRunning}
                    timerRemaining={timerRemaining}
                    isExpanded={expandedItemIds.includes(item.id)}
                    onToggleExpanded={() => toggleItemExpansion(item.id)}
                    onSelect={handleSelect}
                    onComplete={handleComplete}
                    onAdoptHabit={handleAdoptHabit}
                    onStartTimer={handleStartTimer}
                  />
                )
              })}
            </div>
          </article>
        ) : null}

        {selectedTimerItem && timerRemaining !== null ? (
          <article className="rounded-[1.6rem] border border-clay-200/80 bg-[#f5efe4] p-5 shadow-soft">
            <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/65">Timer</p>
            <h2 className="mt-1 text-xl font-semibold text-ink-900">{selectedTimerItem.title}</h2>
            <p className="mt-4 text-4xl font-semibold tracking-tight text-ink-900">{timerRemaining}s</p>
            <p className="mt-2 text-sm text-ink-700">Stay with this action until the timer ends. Completion is logged automatically.</p>
          </article>
        ) : null}

        <RecentBatchesCard history={history} />
      </div>
    </section>
  )
}