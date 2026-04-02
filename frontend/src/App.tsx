import { useEffect, useState } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import BottomNav from './components/BottomNav'
import ChatInsightsRail from './components/ChatInsightsRail'
import ChatWindow from './components/ChatWindow'
import InsightsDashboard from './components/InsightsDashboard'
import LoadingScreen from './components/LoadingScreen'
import RecommendationsPage from './components/RecommendationsPage'
import Sidebar from './components/Sidebar'
import { useAppState } from './state/useAppState'

const FIRST_RUN_LOADING_COMPLETE_KEY = 'mindpal:firstRunLoadingComplete'

function Shell() {
  const { error, isInitializing } = useAppState()
  const location = useLocation()
  const isChatRoute = location.pathname === '/chat' || location.pathname === '/'
  const [hasResolvedFirstRun, setHasResolvedFirstRun] = useState(false)
  const [isFirstRunSession, setIsFirstRunSession] = useState(false)
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false)
  const [isInsightsRailOpen, setIsInsightsRailOpen] = useState(true)
  const [isReflectionDrawerOpen, setIsReflectionDrawerOpen] = useState(false)
  const [isInsightsOpen, setIsInsightsOpen] = useState(false)

  useEffect(() => {
    try {
      const hasCompleted = localStorage.getItem(FIRST_RUN_LOADING_COMPLETE_KEY) === '1'
      setIsFirstRunSession(!hasCompleted)
    } catch {
      setIsFirstRunSession(true)
    } finally {
      setHasResolvedFirstRun(true)
    }
  }, [])

  useEffect(() => {
    if (!hasResolvedFirstRun || !isFirstRunSession || isInitializing) {
      return
    }

    try {
      localStorage.setItem(FIRST_RUN_LOADING_COMPLETE_KEY, '1')
    } catch {
      // Ignore storage errors and continue without persisting first-run completion.
    }

    setIsFirstRunSession(false)
  }, [hasResolvedFirstRun, isFirstRunSession, isInitializing])

  const showInitialLoadingScreen = hasResolvedFirstRun && isFirstRunSession && isInitializing

  const handleOpenReflectionDrawer = () => {
    setIsReflectionDrawerOpen(true)
  }

  const handleOpenInsights = () => {
    setIsInsightsRailOpen(true)
    if (window.matchMedia('(max-width: 1023px)').matches) {
      setIsInsightsOpen(true)
    }
  }

  return (
    <main className="relative h-[100dvh] min-h-0 overflow-hidden bg-[radial-gradient(circle_at_top_left,_rgba(234,224,212,0.55),_rgba(246,241,234,0.98)_56%)] font-body text-ink-800">
      <LoadingScreen isVisible={showInitialLoadingScreen} variant="initial" />
      <div className="absolute -left-24 top-10 h-64 w-64 rounded-full bg-sage-100/45 blur-3xl" />
      <div className="absolute -right-16 bottom-16 h-72 w-72 rounded-full bg-clay-200/35 blur-3xl" />
      <div
        className={`absolute inset-y-0 hidden w-px bg-clay-200/60 lg:block transition-[left] duration-200 ease-in-out ${isSidebarCollapsed ? 'left-16' : 'left-[21.5rem]'}`}
      />
      {isChatRoute && isInsightsRailOpen ? (
        <div className="absolute inset-y-0 right-[17.5rem] hidden w-px bg-clay-200/60 lg:block" />
      ) : null}

      <div className="relative z-10 flex h-full min-h-0">
        <Sidebar
          className="hidden lg:block"
          isCollapsed={isSidebarCollapsed}
          onToggleCollapse={() => setIsSidebarCollapsed((c) => !c)}
        />

        <section className="flex h-full min-h-0 flex-1 flex-col bg-sand-50/72">
          {error ? (
            <div className="px-4 pt-4 sm:px-6">
              <p className="rounded-soft border border-clay-200 bg-clay-100 px-4 py-2 text-sm text-ink-800">{error}</p>
            </div>
          ) : null}

          <div className="flex min-h-0 flex-1">
            <div key={location.pathname} className="min-w-0 flex-1 pb-16 page-enter lg:pb-0">
              <Routes>
                <Route
                  path="/chat"
                  element={
                    <ChatWindow onOpenInsights={handleOpenInsights} />
                  }
                />
                <Route path="/insights" element={<InsightsDashboard />} />
                <Route path="/recommendations" element={<RecommendationsPage />} />
                <Route path="*" element={<Navigate to="/chat" replace />} />
              </Routes>
            </div>

            {isChatRoute && isInsightsRailOpen ? (
              <ChatInsightsRail className="hidden lg:block lg:w-[280px]" onClose={() => setIsInsightsRailOpen(false)} />
            ) : null}
          </div>
        </section>

        {isReflectionDrawerOpen ? (
          <div className="fixed inset-0 z-40 flex lg:hidden" role="dialog" aria-modal="true">
            <button
              type="button"
              className="flex-1 bg-ink-900/35"
              aria-label="Close reflection panel"
              onClick={() => setIsReflectionDrawerOpen(false)}
            />
            <Sidebar
              className="w-[86%] max-w-[320px]"
              hideNav
              onNavigate={() => setIsReflectionDrawerOpen(false)}
              onClose={() => setIsReflectionDrawerOpen(false)}
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

      <BottomNav onOpenNavigation={handleOpenReflectionDrawer} />
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
