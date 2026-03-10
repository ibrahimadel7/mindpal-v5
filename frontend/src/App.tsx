import { useState } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import ChatInsightsRail from './components/ChatInsightsRail'
import ChatWindow from './components/ChatWindow'
import InsightsDashboard from './components/InsightsDashboard'
import Sidebar from './components/Sidebar'
import { useAppState } from './state/useAppState'

function Shell() {
  const { error } = useAppState()
  const location = useLocation()
  const isChatRoute = location.pathname === '/chat' || location.pathname === '/'
  const [isSidebarOpen, setIsSidebarOpen] = useState(true)
  const [isInsightsRailOpen, setIsInsightsRailOpen] = useState(true)
  const [isNavOpen, setIsNavOpen] = useState(false)
  const [isInsightsOpen, setIsInsightsOpen] = useState(false)

  const handleOpenNavigation = () => {
    setIsSidebarOpen(true)
    if (window.matchMedia('(max-width: 1023px)').matches) {
      setIsNavOpen(true)
    }
  }

  const handleOpenInsights = () => {
    setIsInsightsRailOpen(true)
    if (window.matchMedia('(max-width: 1023px)').matches) {
      setIsInsightsOpen(true)
    }
  }

  return (
    <main className="relative h-[100dvh] min-h-0 overflow-hidden bg-[radial-gradient(circle_at_top_left,_rgba(234,224,212,0.55),_rgba(246,241,234,0.98)_56%)] font-body text-ink-800">
      <div className="absolute -left-24 top-10 h-64 w-64 rounded-full bg-sage-100/45 blur-3xl" />
      <div className="absolute -right-16 bottom-16 h-72 w-72 rounded-full bg-clay-200/35 blur-3xl" />
      {isSidebarOpen ? <div className="absolute inset-y-0 left-[21.5rem] hidden w-px bg-clay-200/60 lg:block" /> : null}
      {isChatRoute && isInsightsRailOpen ? (
        <div className="absolute inset-y-0 right-[17.5rem] hidden w-px bg-clay-200/60 lg:block" />
      ) : null}

      <div className="relative z-10 flex h-full min-h-0">
        {isSidebarOpen ? <Sidebar className="hidden lg:block lg:w-[344px]" onClose={() => setIsSidebarOpen(false)} /> : null}

        <section className="flex h-full min-h-0 flex-1 flex-col bg-sand-50/72">
          {error ? (
            <div className="px-4 pt-4 sm:px-6">
              <p className="rounded-soft border border-clay-200 bg-clay-100 px-4 py-2 text-sm text-ink-800">{error}</p>
            </div>
          ) : null}

          <div className="flex min-h-0 flex-1">
            <div className="min-w-0 flex-1">
              <Routes>
                <Route
                  path="/chat"
                  element={
                    <ChatWindow
                      onOpenNavigation={handleOpenNavigation}
                      onOpenInsights={handleOpenInsights}
                    />
                  }
                />
                <Route path="/insights" element={<InsightsDashboard onOpenNavigation={handleOpenNavigation} />} />
                <Route path="*" element={<Navigate to="/chat" replace />} />
              </Routes>
            </div>

            {isChatRoute && isInsightsRailOpen ? (
              <ChatInsightsRail className="hidden lg:block lg:w-[280px]" onClose={() => setIsInsightsRailOpen(false)} />
            ) : null}
          </div>
        </section>

        {isNavOpen ? (
          <div className="fixed inset-0 z-40 flex lg:hidden" role="dialog" aria-modal="true">
            <button
              type="button"
              className="flex-1 bg-ink-900/35"
              aria-label="Close navigation panel"
              onClick={() => setIsNavOpen(false)}
            />
            <Sidebar
              className="w-[86%] max-w-[320px]"
              onNavigate={() => setIsNavOpen(false)}
              onClose={() => setIsNavOpen(false)}
            />
          </div>
        ) : null}

        {isChatRoute && isInsightsOpen ? (
          <div className="fixed inset-0 z-40 flex justify-end lg:hidden" role="dialog" aria-modal="true">
            <button
              type="button"
              className="flex-1 bg-ink-900/35"
              aria-label="Close insights panel"
              onClick={() => setIsInsightsOpen(false)}
            />
            <ChatInsightsRail className="w-[86%] max-w-[320px]" onClose={() => setIsInsightsOpen(false)} />
          </div>
        ) : null}
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
