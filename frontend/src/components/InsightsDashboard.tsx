import { useEffect } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { useAppState } from '../state/useAppState'

export default function InsightsDashboard() {
  const { insights, fetchInsights, isLoadingInsights } = useAppState()

  useEffect(() => {
    void fetchInsights()
  }, [fetchInsights])

  return (
    <section className="h-full overflow-y-auto px-6 py-6">
      <div className="mx-auto flex w-full max-w-5xl flex-col gap-5">
        <header>
          <h1 className="font-heading text-4xl text-ink-900">Insights</h1>
          <p className="mt-1 text-sm text-ink-700">Gentle patterns from your reflections over time.</p>
        </header>

        {isLoadingInsights ? <p className="text-sm text-ink-700/75">Loading insights...</p> : null}

        <article className="rounded-soft border border-clay-200 bg-white/90 p-4 shadow-soft">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-[0.12em] text-ink-700">Emotion Frequency</h2>
          {insights.emotions.length ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={insights.emotions}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e8dccd" />
                  <XAxis dataKey="label" stroke="#6b5e52" />
                  <YAxis stroke="#6b5e52" allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#c6a88e" radius={[10, 10, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <p className="text-sm text-ink-700/70">No emotion insights yet.</p>
          )}
        </article>

        <article className="rounded-soft border border-clay-200 bg-white/90 p-4 shadow-soft">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-[0.12em] text-ink-700">Habit Frequency</h2>
          {insights.habits.length ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={insights.habits}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e8dccd" />
                  <XAxis dataKey="habit" stroke="#6b5e52" />
                  <YAxis stroke="#6b5e52" allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="count" fill="#9fb194" radius={[10, 10, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <p className="text-sm text-ink-700/70">No habit insights yet.</p>
          )}
        </article>

        <article className="rounded-soft border border-clay-200 bg-white/90 p-4 shadow-soft">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-[0.12em] text-ink-700">Time-based Emotion Patterns</h2>
          {insights.timePatterns.length ? (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={insights.timePatterns}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e8dccd" />
                  <XAxis dataKey="hour_of_day" stroke="#6b5e52" />
                  <YAxis stroke="#6b5e52" allowDecimals={false} />
                  <Tooltip />
                  <Line type="monotone" dataKey="message_count" stroke="#ae8669" strokeWidth={3} dot={{ r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <p className="text-sm text-ink-700/70">No time pattern insights yet.</p>
          )}
        </article>
      </div>
    </section>
  )
}
