import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Navigate, Route, Routes } from 'react-router'
import { useAuth } from './hooks/useAuth'
import LoginPage from './components/LoginPage'
import RequireAuth from './components/RequireAuth'
import AppShell from './components/AppShell'
import LandingPage from './pages/LandingPage'
import SchedulePlaceholderPage from './pages/SchedulePlaceholderPage'

interface GreetingResponse {
  message: string
}

function isGreetingResponse(payload: unknown): payload is GreetingResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'message' in payload &&
    typeof payload.message === 'string'
  )
}

// Temporary home content until the landing page replaces it.
function GreetingHomePage() {
  const { token, logout } = useAuth()
  const { t } = useTranslation()
  const [message, setMessage] = useState<string | null>(null)
  const [fetchError, setFetchError] = useState<string | null>(null)

  useEffect(() => {
    if (!token) return

    const controller = new AbortController()

    async function loadGreeting() {
      try {
        const response = await fetch('/api/v1/hello', {
          signal: controller.signal,
          headers: {
            Authorization: `Bearer ${token}`,
          },
        })

        if (response.status === 401) {
          logout()
          return
        }

        if (!response.ok) {
          throw new Error(`Request failed with status ${response.status}`)
        }

        const payload: unknown = await response.json()

        if (!isGreetingResponse(payload)) {
          throw new Error('Response did not include a message')
        }

        setMessage(payload.message)
      } catch {
        if (!controller.signal.aborted) {
          setFetchError('Unable to load the greeting. Please try again later.')
        }
      }
    }

    loadGreeting()

    return () => controller.abort()
  }, [token, logout])

  return (
    <div className="min-h-dvh flex flex-col items-center justify-center gap-4">
      <h1 className="text-3xl font-bold">
        {fetchError || message || 'Loading greeting...'}
      </h1>
      <button
        onClick={logout}
        className="min-h-11 rounded bg-gray-200 px-4 py-2 hover:bg-gray-300"
      >
        {t('auth.logOut')}
      </button>
    </div>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<RequireAuth />}>
        <Route element={<AppShell />}>
          <Route path="/" element={<LandingPage />} />
          <Route path="/schedule" element={<SchedulePlaceholderPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
