import { useEffect, useState } from 'react'

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
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const controller = new AbortController()

    async function loadGreeting() {
      try {
        const response = await fetch('/api/v1/hello', { signal: controller.signal })

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
          setError('Unable to load the greeting. Please try again later.')
        }
      }
    }

    loadGreeting()

    return () => controller.abort()
  }, [])

  return (
    <div className="min-h-screen flex items-center justify-center">
      <h1 className="text-3xl font-bold">
        {error || message || 'Loading greeting...'}
      </h1>
    </div>
  )
}
