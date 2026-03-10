import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import ChatWindow from './components/ChatWindow'
import InsightsDashboard from './components/InsightsDashboard'
import Sidebar from './components/Sidebar'
import { useAppState } from './state/useAppState'

function Shell() {
  const { error } = useAppState()

  return (
    <main className="relative min-h-screen overflow-hidden bg-[radial-gradient(circle_at_top_left,_rgba(229,216,200,0.45),_rgba(248,244,239,0.95)_52%)] font-body text-ink-800">
      <div className="absolute -left-20 top-16 h-56 w-56 rounded-full bg-sage-100/35 blur-3xl" />
      <div className="absolute bottom-20 right-8 h-60 w-60 rounded-full bg-clay-200/30 blur-3xl" />

      <div className="relative z-10 flex min-h-screen flex-col md:flex-row">
        <Sidebar />
        <section className="h-[calc(100vh-0px)] flex-1 bg-sand-50/70">
          {error ? (
            <div className="px-6 pt-4">
              <p className="rounded-soft border border-clay-200 bg-clay-100 px-4 py-2 text-sm text-ink-800">{error}</p>
            </div>
          ) : null}
          <Routes>
            <Route path="/chat" element={<ChatWindow />} />
            <Route path="/insights" element={<InsightsDashboard />} />
            <Route path="*" element={<Navigate to="/chat" replace />} />
          </Routes>
        </section>
      </div>
    </main>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <Shell />
    </BrowserRouter>
  )
}
