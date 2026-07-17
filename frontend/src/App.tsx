import { useEffect, useState } from 'react'
import { useAuth } from './hooks/useAuth'
import LoginPage from './components/LoginPage'

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

export default function App() {
  const { isAuthenticated, token, logout, login, isLoading, error } = useAuth()
  const [message, setMessage] = useState<string | null>(null)
  const [fetchError, setFetchError] = useState<string | null>(null)

  useEffect(() => {
    if (!isAuthenticated || !token) return

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
  }, [isAuthenticated, token, logout])

  if (!isAuthenticated) {
    return <LoginPage login={login} isLoading={isLoading} error={error} />
  }

  return (
    <div className="min-h-full flex flex-col items-center justify-center gap-4">
      <h1 className="text-3xl font-bold">
        {fetchError || message || 'Loading greeting...'}
      </h1>
      <button
        onClick={logout}
        className="rounded bg-gray-200 px-4 py-2 hover:bg-gray-300"
      >
        Log out
      </button>
    </div>
  )
}
