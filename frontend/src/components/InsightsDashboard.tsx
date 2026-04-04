import { useEffect, useMemo, useState } from 'react'
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from 'recharts'
import { useAppState } from '../state/useAppState'
import LoadingScreen from './LoadingScreen'

interface InsightsDashboardProps {
  onOpenNavigation?: () => void
}

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

function normalizeEmotionLabel(label: string): string {
  return label.trim().toLowerCase()
}

function toMoodLevel(score: number): 'Balanced' | 'Uplifted' | 'Tender' | 'Heavy' {
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

function prettify(value: string): string {
  return value
    .replaceAll('_', ' ')
    .split(' ')
    .filter(Boolean)
    .map((word) => `${word[0]?.toUpperCase() ?? ''}${word.slice(1)}`)
    .join(' ')
}

function formatShortDate(date: string): string {
  const parsed = new Date(date)
  if (Number.isNaN(parsed.getTime())) return date
  const weekday = parsed.toLocaleDateString('en-US', { weekday: 'short' })
  const monthDay = parsed.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  return `${weekday} · ${monthDay}`
}

const warmChartPalette = ['#bf8a72', '#c89a77', '#d7b08a', '#c9958a', '#b79282', '#e2cab0']

const emotionColorMap: Record<string, string> = {
  joy: '#e2cab0',
  excitement: '#c9958a',
  gratitude: '#c89a77',
  calm: '#b79282',
  neutral: '#d8bea4',
  anxiety: '#d6a88c',
  fear: '#d4b189',
  frustration: '#bd8777',
  sadness: '#ad8a7a',
  anger: '#bf8476',
}

const chartTrackColor = '#eee2d5'
const chartSurfaceColor = '#f8f1e9'
const chartStrokeColor = '#f5ebe0'
const chartTooltipBorderColor = '#d9c4b1'
const chartBarShadow = '0 9px 18px -14px rgba(104, 74, 54, 0.28)'

function getChartColor(index: number): string {
  return warmChartPalette[index % warmChartPalette.length]
}

function getEmotionChartColor(label: string, index: number): string {
  return emotionColorMap[normalizeEmotionLabel(label)] ?? getChartColor(index)
}

export default function InsightsDashboard({ onOpenNavigation }: InsightsDashboardProps) {
  const { insights, fetchInsights, isLoadingInsights, conversations, messagesByConversation } = useAppState()

  const moodSummary = useMemo(() => {
    if (!insights.emotions.length) {
      return { mood: 'Balanced' as const, entryCount: 0 }
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

  const [daysBack, setDaysBack] = useState(0)

  const emotionFrequencyData = useMemo(() => {
    const emotions = insights.emotions.map((item, index) => ({
      label: prettify(item.label),
      count: item.count,
      color: getEmotionChartColor(item.label, index),
    }))
    const maxCount = Math.max(...emotions.map((item) => item.count), 1)

    return emotions.map((item) => ({
      ...item,
      height: Math.max(34, Math.round((item.count / maxCount) * 100)),
    }))
  }, [insights.emotions])

  const habitPieData = useMemo(
    () => {
      const fallbackTotal = insights.habits.reduce((sum, row) => sum + row.count, 0)
      const total = insights.overview?.total_messages ?? fallbackTotal

      return insights.habits.slice(0, 5).map((row, index) => ({
        habit: prettify(row.habit || 'Unknown'),
        count: row.count,
        percentage: total > 0 ? Math.round((row.count / total) * 100) : 0,
        color: getChartColor(index),
      }))
    },
    [insights.habits, insights.overview],
  )

  const associationData = useMemo(() => {
    const links = insights.habitEmotionLinks.slice(0, 6).map((row, index) => {
      const strengthPct = Number.isFinite(row.link_strength) ? row.link_strength * 100 : 0
      return {
        habit: prettify(row.habit),
        emotion: prettify(row.emotion),
        coOccurrence: row.co_occurrence,
        habitTotal: row.habit_total,
        linkStrengthLabel: `${strengthPct.toFixed(1)}%`,
        color: getEmotionChartColor(row.emotion, index),
      }
    })

    const grouped = new Map<
      string,
      {
        habit: string
        links: {
          emotion: string
          coOccurrence: number
          habitTotal: number
          linkStrengthLabel: string
          color: string
        }[]
      }
    >()

    links.forEach((link) => {
      if (!grouped.has(link.habit)) {
        grouped.set(link.habit, { habit: link.habit, links: [] })
      }

      grouped.get(link.habit)?.links.push({
        emotion: link.emotion,
        coOccurrence: link.coOccurrence,
        habitTotal: link.habitTotal,
        linkStrengthLabel: link.linkStrengthLabel,
        color: link.color,
      })
    })

    return Array.from(grouped.values())
  }, [insights.habitEmotionLinks])

  const widgetDayData = useMemo(() => {
    const trends = insights.emotionTrends
    if (!trends.length) return null
    const idx = Math.max(0, trends.length - 1 - daysBack)
    const day = trends[idx]
    if (!day) return null
    const total = day.total || day.emotions.reduce((s, e) => s + e.count, 0)
    const emotions = day.emotions.map((e, index) => ({
      label: prettify(e.label),
      count: e.count,
      pct: total > 0 ? Math.round((e.count / total) * 100) : 0,
      color: getEmotionChartColor(e.label, index),
    }))
    return {
      dateLabel: formatShortDate(day.date),
      emotions,
      total,
      isToday: daysBack === 0,
    }
  }, [insights.emotionTrends, daysBack])

  useEffect(() => {
    void fetchInsights()
  }, [fetchInsights])

  return (
      <>
        <LoadingScreen isVisible={isLoadingInsights} variant="insights" />
    <section className="h-full overflow-y-auto px-4 py-4 sm:px-6 sm:py-5 lg:px-8">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-5">
        <header className="flex items-start justify-between gap-4">
          <div>
          {onOpenNavigation ? (
            <button
              type="button"
              onClick={onOpenNavigation}
              className="subtle-icon-button mb-3"
              aria-label="Open sidebar"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.9" aria-hidden="true">
                <path d="M4 7h16" strokeLinecap="round" />
                <path d="M4 12h16" strokeLinecap="round" />
                <path d="M4 17h16" strokeLinecap="round" />
              </svg>
            </button>
          ) : null}
            <h1 className="font-heading text-3xl text-ink-900 sm:text-4xl">Emotional Patterns</h1>
            <p className="mt-1 text-sm text-ink-700">A curated view of your internal landscape.</p>
          </div>

          <div className="hidden items-center gap-2 rounded-full border border-clay-200/80 bg-white/90 p-1 sm:flex">
            <button type="button" className="rounded-full bg-clay-200 px-3 py-1 text-xs font-semibold text-ink-900">
              7 Days
            </button>
            <button type="button" className="rounded-full px-3 py-1 text-xs font-semibold text-ink-700/80">
              30 Days
            </button>
          </div>
        </header>


        <div className="grid gap-4 lg:grid-cols-[minmax(0,1.7fr)_290px]">
          <div className="space-y-4">
            <article className="rounded-[1.85rem] bg-[linear-gradient(170deg,rgba(255,255,255,0.98)_0%,rgba(248,244,238,0.94)_100%)] p-4 shadow-soft sm:p-5">
              <div className="flex items-start justify-between gap-3">
                <h2 className="font-heading text-[1.9rem] leading-none text-ink-900 sm:text-[2.05rem]">Emotion Frequency</h2>
                <span className="mt-1 rounded-full bg-clay-100/85 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.08em] text-ink-700">All emotions</span>
              </div>

              {emotionFrequencyData.length ? (
                <div className="mt-6 grid grid-cols-[repeat(auto-fit,minmax(110px,1fr))] items-end gap-2.5 sm:gap-3">
                  {emotionFrequencyData.map((item) => (
                    <div key={item.label} className="flex w-full flex-col items-center gap-2.5">
                      <span className="text-[11px] font-semibold uppercase tracking-[0.08em] text-ink-700/75 sm:text-xs">
                        {item.count}
                      </span>
                      <div
                        className="flex h-44 w-full max-w-[100px] items-end justify-center rounded-[1.15rem] p-1.5 sm:h-48 sm:max-w-[110px]"
                        style={{ backgroundColor: chartSurfaceColor }}
                      >
                        <div
                          className="w-full rounded-[0.95rem] transition-all duration-300"
                          style={{
                            height: `${item.height}%`,
                            backgroundColor: item.color,
                            boxShadow: chartBarShadow,
                          }}
                        />
                      </div>
                      <span className="min-h-[2.2rem] text-center text-[11px] font-semibold uppercase leading-tight tracking-[0.08em] text-ink-700/80 sm:min-h-[2.35rem] sm:text-xs">
                        {item.label}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="mt-4 text-sm text-ink-700/70">No emotion insights yet.</p>
              )}
            </article>

            <article className="rounded-[1.5rem] border border-clay-200/70 bg-white/95 p-5 shadow-soft">
              <div className="flex items-center justify-between gap-3">
                <h2 className="text-[1.35rem] font-semibold text-ink-900">Habit Frequency</h2>
                <span className="text-[10px] font-bold uppercase tracking-[0.16em] text-clay-300">Most Frequent</span>
              </div>

              {habitPieData.length ? (
                <div className="mt-4 grid gap-4 md:grid-cols-[minmax(0,1.1fr)_minmax(0,1fr)] md:items-center">
                  <div className="h-56 w-full rounded-soft border border-clay-100 p-2" style={{ backgroundColor: chartSurfaceColor }}>
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={habitPieData}
                          dataKey="count"
                          nameKey="habit"
                          outerRadius={92}
                          stroke={chartStrokeColor}
                          strokeWidth={2}
                          isAnimationActive
                        >
                          {habitPieData.map((slice) => (
                            <Cell key={slice.habit} fill={slice.color} />
                          ))}
                        </Pie>
                        <Tooltip
                          formatter={(value, _name, item) => {
                            const numericValue = typeof value === 'number' ? value : Number(value ?? 0)
                            const entry = item?.payload as { percentage?: number } | undefined
                            return [`${numericValue} messages (${entry?.percentage ?? 0}%)`, 'Share']
                          }}
                          contentStyle={{ borderRadius: '0.75rem', border: `1px solid ${chartTooltipBorderColor}`, fontSize: '12px' }}
                        />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>

                  <div className="space-y-2.5">
                    {habitPieData.map((slice) => (
                      <div key={slice.habit} className="rounded-soft border border-clay-100 bg-sand-50/70 px-3 py-2.5">
                        <div className="flex items-center justify-between gap-3">
                          <div className="flex items-center gap-2">
                            <span className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: slice.color }} aria-hidden="true" />
                            <p className="text-sm font-semibold text-ink-900">{slice.habit}</p>
                          </div>
                          <p className="text-xs font-semibold text-ink-700">{slice.percentage}%</p>
                        </div>
                        <p className="mt-0.5 text-xs text-ink-700">{slice.count} messages</p>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <p className="mt-4 text-sm text-ink-700/70">No habit data yet.</p>
              )}
            </article>
            <article className="rounded-[1.5rem] border border-clay-200/80 bg-white/95 p-5 shadow-soft">
              <div className="flex items-center justify-between gap-3">
                <h2 className="text-xl font-semibold text-ink-900">Detailed Patterns</h2>
                {insights.overview ? (
                  <p className="text-xs font-semibold uppercase tracking-[0.14em] text-ink-700/65">
                    {insights.overview.total_messages} Messages / {insights.overview.active_days} Active Days
                  </p>
                ) : null}
              </div>

              {associationData.length ? (
                <div className="mt-4 space-y-2.5">
                  {associationData.map((group) => (
                    <div key={group.habit} className="rounded-soft border border-clay-100 bg-sand-50/65 px-3.5 py-3">
                      <div className="flex items-center justify-between gap-2">
                        <p className="text-sm font-semibold text-ink-900">{group.habit}</p>
                        <span className="text-[11px] font-semibold uppercase tracking-[0.08em] text-ink-700/70">
                          {group.links.length} {group.links.length === 1 ? 'link' : 'links'}
                        </span>
                      </div>

                      <div className="mt-2.5 flex flex-wrap gap-2">
                        {group.links.map((link) => (
                          <span
                            key={`${group.habit}-${link.emotion}`}
                            className="inline-flex items-center gap-2 rounded-full border px-2.5 py-1.5 text-xs"
                            style={{ borderColor: link.color, backgroundColor: `${link.color}1f` }}
                          >
                            <span className="font-semibold text-ink-900">{link.emotion}</span>
                            <span className="text-ink-700/85">
                              {link.coOccurrence}/{link.habitTotal}
                            </span>
                            <span className="rounded-full bg-white/75 px-1.5 py-0.5 text-[10px] font-semibold text-ink-700">
                              {link.linkStrengthLabel}
                            </span>
                          </span>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="mt-4 text-sm text-ink-700/70">No association data yet.</p>
              )}
            </article>
          </div>

          <aside className="space-y-5">
            <section>
              <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-ink-700/65">Today's Mood Map</p>
              <article className="mt-3 rounded-[1.35rem] border border-clay-200/80 bg-clay-100/75 px-4 py-5">
                <p className="text-4xl font-semibold text-clay-400">{moodSummary.mood}</p>
                <p className="mt-1 text-xs text-ink-700/80">Based on {moodSummary.entryCount} insight entries today</p>
                {insights.overview?.dominant_emotion ? (
                  <p className="mt-4 text-xs uppercase tracking-[0.12em] text-ink-700/70">
                    Dominant emotion: {prettify(insights.overview.dominant_emotion)}
                  </p>
                ) : null}
              </article>
            </section>

            <article className="rounded-[1.2rem] bg-[#1f1813] px-4 py-5 text-center text-sand-50 shadow-soft">
              <p className="text-3xl leading-none">{streak}</p>
              <p className="mt-1 text-2xl font-semibold">Day Streak</p>
              <p className="mt-1 text-[11px] uppercase tracking-[0.13em] text-sand-100/70">You're doing great</p>
            </article>

            <article className="rounded-[1.2rem] border border-clay-200/75 bg-white/95 p-4 shadow-soft">
              <div className="flex items-center justify-between gap-2">
                <p className="text-sm font-semibold text-ink-900">
                  {widgetDayData ? widgetDayData.dateLabel : '—'}
                </p>
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    aria-label="Previous day"
                    disabled={!insights.emotionTrends.length || daysBack >= insights.emotionTrends.length - 1}
                    onClick={() => setDaysBack((prev) => prev + 1)}
                    className="subtle-icon-button disabled:pointer-events-none disabled:opacity-30"
                  >
                    <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                      <path d="M15 18l-6-6 6-6" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </button>
                  <button
                    type="button"
                    aria-label="Next day"
                    disabled={daysBack === 0}
                    onClick={() => setDaysBack((prev) => prev - 1)}
                    className="subtle-icon-button disabled:pointer-events-none disabled:opacity-30"
                  >
                    <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                      <path d="M9 18l6-6-6-6" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </button>
                </div>
              </div>
              {widgetDayData ? (
                <>
                  <p className="mt-1 text-[10px] font-semibold uppercase tracking-[0.14em] text-ink-700/55">
                    Emotions · {widgetDayData.total} {widgetDayData.total === 1 ? 'entry' : 'entries'}
                  </p>
                  {widgetDayData.emotions.length ? (
                    <div className="mt-3 space-y-2.5">
                      {widgetDayData.emotions.map((e) => (
                        <div key={e.label}>
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-medium text-ink-800">{e.label}</span>
                            <span className="font-semibold text-ink-800">{e.pct}%</span>
                          </div>
                          <div className="mt-1 h-1.5 w-full rounded-full" style={{ backgroundColor: chartTrackColor }}>
                            <div
                              className="h-1.5 rounded-full transition-all"
                              style={{ width: `${Math.max(e.pct, 4)}%`, backgroundColor: e.color }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="mt-2 text-sm text-ink-700/70">No emotion data for this day.</p>
                  )}
                </>
              ) : (
                <p className="mt-2 text-sm text-ink-700/70">No emotion data yet.</p>
              )}
            </article>
          </aside>
        </div>

        {!insights.overview && !insights.emotions.length && !insights.habitEmotionLinks.length ? (
          <p className="text-sm text-ink-700/70">No insights available yet. Continue reflecting to unlock your dashboard.</p>
        ) : null}

        {insights.overview ? (
          <article className="rounded-[1.2rem] border border-clay-200/70 bg-white/85 px-4 py-3 text-xs text-ink-700/85">
            Snapshot: {insights.overview.total_messages} total messages over {insights.overview.active_days} active days
            {insights.overview.dominant_habit ? `, led by ${prettify(insights.overview.dominant_habit).toLowerCase()}` : ''}.
          </article>
        ) : null}
      </div>

    </section>
      </>
  )
}
