import { useContext } from 'react'
import { AppStateContext, type AppState } from './AppStateStore'

export function useAppState(): AppState {
  const context = useContext(AppStateContext)
  if (!context) {
    throw new Error('useAppState must be used within AppStateProvider')
  }
  return context
}
