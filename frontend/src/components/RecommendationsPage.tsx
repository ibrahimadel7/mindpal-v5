import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import LoadingScreen from './LoadingScreen'
import {
  adoptRecommendationItem,
  completeRecommendationItem,
  createHabit,
  deleteHabit,
  generateRecommendations,
  getHabitChecklist,
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

const categories: Array<{ value: RecommendationCategory; label: string }> = [
  { value: 'balance', label: 'Balance' },
  { value: 'calm', label: 'Calm' },
  { value: 'focus', label: 'Focus' },
  { value: 'energy', label: 'Energy' },
  { value: 'reflection', label: 'Reflection' },
]

const categoryContextLines: Record<RecommendationCategory, string> = {
  balance: 'Based on your recent pattern of balancing effort and recovery.',
  calm: 'Based on your recent stress patterns and the need to soften the pace.',
  focus: 'Based on your recent attention patterns and moments of fragmentation.',
  energy: 'Based on your recent low-energy patterns and movement cues.',
  reflection: 'Based on your recent reflection patterns and follow-up prompts.',
}

const moodOptions = [
  { value: 'calm', emoji: '🙂', label: 'Calm' },
  { value: 'steady', emoji: '😌', label: 'Steady' },
  { value: 'mixed', emoji: '😐', label: 'Mixed' },
  { value: 'heavy', emoji: '😮‍💨', label: 'Heavy' },
] as const

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
    <label className="block w-full sm:max-w-[220px]">
      <span className="mb-2 block text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/60">Category</span>
      <select
        value={selectedCategory}
        onChange={(e) => onSelect(e.target.value as RecommendationCategory)}
        className="w-full rounded-full border border-clay-200 bg-white px-4 py-3 text-sm font-semibold text-ink-900 shadow-soft outline-none transition duration-200 focus:border-clay-300 focus:ring-2 focus:ring-clay-300"
      >
        {categories.map((category) => (
          <option key={category.value} value={category.value}>
            {category.label}
          </option>
        ))}
      </select>
    </label>
  )
}

interface RecommendationFocusCardProps {
  item: RecommendationItem | null
  currentIndex: number
  totalCount: number
  isBusy: boolean
  isTimerRunning: boolean
  timerRemaining: number | null
  primaryLabel: string
  contextLine: string
  onPrimary: () => void
  onNext: () => void
  onSkip: () => void
}

function RecommendationFocusCard({
  item,
  currentIndex,
  totalCount,
  isBusy,
  isTimerRunning,
  timerRemaining,
  primaryLabel,
  contextLine,
  onPrimary,
  onNext,
  onSkip,
}: RecommendationFocusCardProps) {
  if (!item) {
    return (
      <article className="rounded-[1.5rem] border border-clay-200 bg-white p-5 shadow-[0_24px_60px_-28px_rgba(109,82,45,0.28)] sm:p-6">
        <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/60">Recommendation</p>
        <h2 className="mt-2 text-2xl font-semibold text-ink-900">You&apos;re done for now</h2>
        <p className="mt-3 text-sm leading-6 text-ink-700/75">Refresh the batch to load a new recommendation set.</p>
      </article>
    )
  }

  const isCompleted = item.status === 'completed'
  const isPrimaryDisabled = isBusy || isCompleted || (item.kind === 'timed_action' && isTimerRunning)
  const progressIndex = Math.min(currentIndex, Math.max(totalCount - 1, 0))
  const progressDots = Math.min(totalCount, 5)

  return (
    <article className="rounded-[1.5rem] border border-clay-200 bg-white p-5 shadow-[0_24px_60px_-28px_rgba(109,82,45,0.28)] sm:p-6">
      <div className="flex items-start justify-between gap-3">
        <div className="space-y-2">
          <div className="flex items-center gap-3 text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/60">
            <span>
              Item {currentIndex + 1} of {totalCount}
            </span>
            <span aria-hidden="true">•</span>
            <span>{formatKind(item.kind)}</span>
          </div>
          <div className="flex gap-1.5" aria-label="Recommendation progress">
            {Array.from({ length: progressDots }).map((_, index) => (
              <span
                key={`${item.id}-dot-${index}`}
                className={`h-2.5 w-2.5 rounded-full transition-all duration-300 ${
                  index <= progressIndex ? 'bg-ink-900 scale-110 animate-dot-pop' : 'bg-clay-200'
                }`}
              />
            ))}
          </div>
        </div>

        <span className="rounded-full bg-sand-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-700">
          {item.status}
        </span>
      </div>

      <div className="mt-5 pt-1">
        <p className="text-[11px] font-medium uppercase tracking-[0.14em] text-ink-700/55">Context</p>
        <p className="mt-1 text-sm leading-6 text-ink-700/78">{contextLine}</p>
      </div>

      <h2 className="mt-5 font-heading text-[2rem] text-ink-900 sm:text-[2.35rem]">{item.title}</h2>
      <p className="mt-2 text-sm leading-6 text-ink-700">{item.rationale}</p>

      {item.follow_up_text ? <p className="mt-3 text-sm leading-6 text-ink-700/80">{item.follow_up_text}</p> : null}

      <div className="mt-4 flex flex-wrap gap-2">
        <span className="rounded-full border border-clay-200 bg-sand-50 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-700/70">
          {formatDuration(item.estimated_duration_minutes)}
        </span>
        {item.kind === 'timed_action' && timerRemaining !== null ? (
          <span className="rounded-full border border-clay-200 bg-sand-50 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-ink-700/70">
            {timerRemaining}s remaining
          </span>
        ) : null}
      </div>

      <div className="mt-5 space-y-3">
        <button
          type="button"
          onClick={() => void onPrimary()}
          disabled={isPrimaryDisabled}
          className="flex w-full items-center justify-center rounded-full bg-ink-900 px-4 py-4 text-sm font-semibold text-white transition duration-200 hover:-translate-y-px hover:bg-ink-800 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60"
        >
          {primaryLabel}
        </button>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={onSkip}
            className="flex-1 rounded-full border border-clay-200 bg-white px-4 py-3 text-sm font-semibold text-ink-700 transition duration-200 hover:-translate-y-px hover:bg-sand-100 active:scale-[0.98]"
          >
            Skip
          </button>
          <button
            type="button"
            onClick={onNext}
            className="flex-1 rounded-full border border-clay-200 bg-white px-4 py-3 text-sm font-semibold text-ink-700 transition duration-200 hover:-translate-y-px hover:bg-sand-100 active:scale-[0.98]"
          >
            Next
          </button>
        </div>
      </div>
    </article>
  )
}

interface HabitSummaryProps {
  checklist: DailyHabitChecklistResponse | null
  activeItemIds: number[]
  onToggleHabit: (item: DailyHabitChecklistItem) => Promise<void>
  onRemoveHabit: (item: DailyHabitChecklistItem) => Promise<void>
  onAddHabit: (name: string) => Promise<void>
  isAddingHabit: boolean
}

function HabitSummary({ checklist, activeItemIds, onToggleHabit, onRemoveHabit, onAddHabit, isAddingHabit }: HabitSummaryProps) {
  const [isOpen, setIsOpen] = useState(true)
  const [newHabitName, setNewHabitName] = useState('')

  const completedCount = checklist?.habits.filter((item) => item.is_completed).length ?? 0
  const totalCount = checklist?.habits.length ?? 0

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const trimmed = newHabitName.trim()
    if (!trimmed) return
    await onAddHabit(trimmed)
    setNewHabitName('')
    setIsOpen(true)
  }

  return (
    <section className="rounded-[1.5rem] border border-clay-200 bg-white/96 p-5 shadow-soft sm:p-6">
      <button
        type="button"
        onClick={() => setIsOpen((current) => !current)}
        className="flex w-full items-center justify-between gap-4 text-left transition duration-200 hover:opacity-90 active:scale-[0.99]"
      >
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/60">Today&apos;s habits</p>
          <h3 className="mt-1 text-sm font-semibold text-ink-900">
            {completedCount} of {totalCount} completed
          </h3>
        </div>
        <span className="rounded-full border border-clay-200 bg-sand-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-ink-700/70">
          {isOpen ? 'Hide' : 'Show'}
        </span>
      </button>

      {isOpen ? (
        <div className="mt-4 space-y-3">
          {checklist?.habits.length ? (
            <div className="space-y-2">
              {checklist.habits.map((item) => {
                const isBusy = activeItemIds.includes(item.habit.id)
                return (
                  <div key={item.habit.id} className="flex items-center gap-3 rounded-[1rem] border border-clay-200 bg-sand-50/70 px-3 py-3">
                    <input
                      type="checkbox"
                      checked={item.is_completed}
                      onChange={() => void onToggleHabit(item)}
                      disabled={isBusy}
                      className="h-4 w-4 rounded border-clay-300 text-ink-900 focus:ring-clay-300"
                    />
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold text-ink-900">{item.habit.name}</p>
                      {item.habit.reason_text ? <p className="text-xs leading-5 text-ink-700/70">{item.habit.reason_text}</p> : null}
                    </div>
                    <button
                      type="button"
                      onClick={() => void onRemoveHabit(item)}
                      disabled={isBusy}
                      className="rounded-full border border-clay-200 bg-white px-3 py-2 text-xs font-semibold text-ink-700 transition duration-200 hover:-translate-y-px hover:bg-sand-100 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      Remove
                    </button>
                  </div>
                )
              })}
            </div>
          ) : (
            <p className="rounded-[1rem] border border-dashed border-clay-200 bg-sand-50/60 px-4 py-4 text-sm leading-6 text-ink-700/72">
              No habits yet. Add one below or adopt one from a recommendation.
            </p>
          )}

          <form onSubmit={(e) => void handleSubmit(e)} className="flex flex-col gap-2 sm:flex-row">
            <input
              type="text"
              value={newHabitName}
              onChange={(e) => setNewHabitName(e.target.value)}
              placeholder="Add a habit"
              maxLength={255}
              className="min-w-0 flex-1 rounded-full border border-clay-200 bg-white px-4 py-3 text-sm text-ink-900 placeholder:text-ink-700/45 focus:outline-none focus:ring-2 focus:ring-clay-300"
            />
            <button
              type="submit"
              disabled={isAddingHabit || !newHabitName.trim()}
              className="rounded-full bg-ink-900 px-4 py-3 text-sm font-semibold text-white transition duration-200 hover:-translate-y-px hover:bg-ink-800 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isAddingHabit ? 'Adding...' : 'Add'}
            </button>
          </form>
        </div>
      ) : null}
    </section>
  )
}

export default function RecommendationsPage() {
  const navigate = useNavigate()
  const { userId } = useAppState()
  const [selectedCategory, setSelectedCategory] = useState<RecommendationCategory>('balance')
  const [batch, setBatch] = useState<RecommendationBatch | null>(null)
  const [checklist, setChecklist] = useState<DailyHabitChecklistResponse | null>(null)
  const [pageError, setPageError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isRegenerating, setIsRegenerating] = useState(false)
  const [activeItemIds, setActiveItemIds] = useState<number[]>([])
  const [isAddingHabit, setIsAddingHabit] = useState(false)
  const [timerItemId, setTimerItemId] = useState<number | null>(null)
  const [timerRemaining, setTimerRemaining] = useState<number | null>(null)
  const [currentItemIndex, setCurrentItemIndex] = useState(0)
  const [selectedMood, setSelectedMood] = useState<string | null>(null)

  const currentItem = batch?.items[currentItemIndex] ?? null
  const currentCategoryLabel = categories.find((category) => category.value === selectedCategory)?.label ?? selectedCategory
  const contextLine = categoryContextLines[selectedCategory]
  const moodStorageKey = `mindpal:recommendation-mood:${userId}`

  useEffect(() => {
    try {
      const storedMood = window.localStorage.getItem(moodStorageKey)
      if (storedMood && moodOptions.some((option) => option.value === storedMood)) {
        setSelectedMood(storedMood)
      }
    } catch {
      // Ignore storage failures.
    }
  }, [moodStorageKey])

  useEffect(() => {
    try {
      if (selectedMood) {
        window.localStorage.setItem(moodStorageKey, selectedMood)
      } else {
        window.localStorage.removeItem(moodStorageKey)
      }
    } catch {
      // Ignore storage failures.
    }
  }, [moodStorageKey, selectedMood])

  useEffect(() => {
    if (timerItemId === null || timerRemaining === null || timerRemaining <= 0) {
      return
    }

    const timeout = window.setTimeout(() => {
      setTimerRemaining((current) => (current === null ? null : current - 1))
    }, 1000)

    return () => window.clearTimeout(timeout)
  }, [timerItemId, timerRemaining])

  const loadPage = useCallback(
    async (category: RecommendationCategory) => {
      setIsLoading(true)
      setPageError(null)
      try {
        const [todayBatch, checklistResponse] = await Promise.all([
          getTodayRecommendations(userId, category),
          getHabitChecklist(userId),
        ])
        setBatch(todayBatch)
        setChecklist(checklistResponse)
        setCurrentItemIndex(0)
      } catch {
        setPageError('Recommendations are unavailable right now.')
      } finally {
        setIsLoading(false)
      }
    },
    [userId],
  )

  useEffect(() => {
    void loadPage(selectedCategory)
  }, [loadPage, selectedCategory])

  async function handleRegenerate() {
    setIsRegenerating(true)
    setPageError(null)
    try {
      const nextBatch = await generateRecommendations({ user_id: userId, category: selectedCategory })
      const checklistResponse = await getHabitChecklist(userId)
      setBatch(nextBatch)
      setChecklist(checklistResponse)
      setCurrentItemIndex(0)
    } catch {
      setPageError('A fresh batch could not be generated.')
    } finally {
      setIsRegenerating(false)
    }
  }

  async function runItemAction(itemId: number, action: () => Promise<void>, failureMessage = 'That recommendation action could not be completed.') {
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

  const advanceToNextItem = useCallback(() => {
    setCurrentItemIndex((current) => {
      if (!batch?.items.length) return 0
      return Math.min(current + 1, batch.items.length)
    })
  }, [batch?.items.length])

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
      advanceToNextItem()
    })
  }

  async function handleAdoptHabit(item: RecommendationItem) {
    await runItemAction(item.id, async () => {
      await adoptRecommendationItem(item.id, { user_id: userId })
      const checklistResponse = await getHabitChecklist(userId)
      setChecklist(checklistResponse)
      advanceToNextItem()
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
    if (!confirmed) return

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

  const currentItemBusy = currentItem ? activeItemIds.includes(currentItem.id) : false
  const currentItemPrimaryLabel = currentItem
    ? currentItem.kind === 'timed_action' && timerItemId === currentItem.id && timerRemaining !== null
      ? `Timer ${timerRemaining}s`
      : currentItem.kind === 'timed_action'
        ? 'Start timer'
        : currentItem.kind === 'habit'
          ? 'Add to habits'
          : currentItem.kind === 'reflection'
            ? 'Open in chat'
            : 'Mark complete'
    : 'Continue'

  useEffect(() => {
    if (batch && currentItemIndex > batch.items.length) {
      setCurrentItemIndex(batch.items.length)
    }
  }, [batch, currentItemIndex])

  useEffect(() => {
    if (timerItemId === null || timerRemaining !== 0) {
      return
    }

    const currentCompletedItemId = timerItemId
    setTimerItemId(null)
    setTimerRemaining(null)

    void (async () => {
      try {
        await logRecommendationItemInteraction(currentCompletedItemId, {
          user_id: userId,
          event_type: 'timer_completed',
          payload: {},
        })
        const updated = await completeRecommendationItem(currentCompletedItemId, userId)
        setBatch((current) => {
          if (!current) return current
          return {
            ...current,
            items: current.items.map((entry) => (entry.id === updated.id ? updated : entry)),
          }
        })
        advanceToNextItem()
      } catch {
        setPageError('The timer finished, but completion could not be recorded.')
      }
    })()
  }, [advanceToNextItem, timerItemId, timerRemaining, userId])

  return (
    <>
      <LoadingScreen isVisible={isLoading} variant="recommendations" />
      <section className="h-full overflow-y-auto px-4 py-5 sm:px-6 lg:px-8">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-5 sm:gap-6">
          <header className="space-y-2">
            <h1 className="font-heading text-3xl text-ink-900 sm:text-[2.35rem]">Today — {currentCategoryLabel}</h1>
            <p className="max-w-lg text-sm leading-6 text-ink-700/78">One clear recommendation. Finish it, skip it, or move on.</p>
          </header>

          <div className="flex items-end justify-between gap-3 pb-1">
            <CategorySelector selectedCategory={selectedCategory} onSelect={setSelectedCategory} />
            <button
              type="button"
              onClick={() => void handleRegenerate()}
              disabled={isRegenerating}
              className="rounded-full border border-clay-200 bg-white px-4 py-3 text-sm font-semibold text-ink-700 transition duration-200 hover:-translate-y-px hover:bg-sand-100 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60"
            >
              {isRegenerating ? 'Refreshing...' : 'Refresh'}
            </button>
          </div>

          {pageError ? <p className="rounded-[1rem] border border-clay-200 bg-clay-100 px-4 py-3 text-sm text-ink-800">{pageError}</p> : null}

          <HabitSummary
            checklist={checklist}
            activeItemIds={activeItemIds}
            onToggleHabit={handleToggleHabit}
            onRemoveHabit={handleRemoveHabit}
            onAddHabit={handleAddHabit}
            isAddingHabit={isAddingHabit}
          />

          <RecommendationFocusCard
            item={currentItem}
            currentIndex={currentItemIndex}
            totalCount={batch?.items.length ?? 0}
            isBusy={currentItemBusy}
            isTimerRunning={timerItemId === currentItem?.id}
            timerRemaining={timerRemaining}
            primaryLabel={currentItemPrimaryLabel}
            contextLine={contextLine}
            onPrimary={() => {
              if (!currentItem) return
              if (currentItem.kind === 'reflection') {
                void handleSelect(currentItem)
                return
              }
              if (currentItem.kind === 'timed_action') {
                void handleStartTimer(currentItem)
                return
              }
              if (currentItem.kind === 'habit') {
                void handleAdoptHabit(currentItem)
                return
              }
              void handleComplete(currentItem)
            }}
            onNext={advanceToNextItem}
            onSkip={advanceToNextItem}
          />

          <div className="flex items-center gap-2 pb-1">
            <span className="text-[11px] font-semibold uppercase tracking-[0.18em] text-ink-700/60">Mood</span>
            <div className="flex flex-wrap gap-2">
              {moodOptions.map((option) => {
                const isSelected = selectedMood === option.value
                return (
                  <button
                    key={option.value}
                    type="button"
                    onClick={() => setSelectedMood(option.value)}
                    aria-pressed={isSelected}
                    className={`inline-flex items-center gap-2 rounded-full border px-3 py-2 text-sm font-semibold transition duration-200 hover:-translate-y-px active:scale-[0.98] ${
                      isSelected
                        ? 'border-ink-900 bg-ink-900 text-white'
                        : 'border-clay-200 bg-white text-ink-700 hover:bg-sand-100'
                    }`}
                  >
                    <span aria-hidden="true">{option.emoji}</span>
                    {option.label}
                  </button>
                )
              })}
            </div>
          </div>

          {selectedMood ? (
            <p className="text-sm leading-6 text-ink-700/72">
              Mood saved locally: {moodOptions.find((option) => option.value === selectedMood)?.label}
            </p>
          ) : null}

          {isLoading ? <p className="text-sm text-ink-700/75">Loading recommendations...</p> : null}
        </div>
      </section>
    </>
  )
}
