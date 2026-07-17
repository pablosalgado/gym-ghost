import { useCallback, useMemo, useState } from 'react'

export const AUTH_TOKEN_STORAGE_KEY = 'gym-ghost-auth-token'

interface AuthSuccessResponse {
  token: string
}

interface ApiErrorItem {
  detail: string
}

interface ApiErrorResponse {
  errors: ApiErrorItem[]
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function isAuthSuccessResponse(payload: unknown): payload is AuthSuccessResponse {
  return isRecord(payload) && typeof payload.token === 'string'
}

function isApiErrorResponse(payload: unknown): payload is ApiErrorResponse {
  return (
    isRecord(payload) &&
    Array.isArray(payload.errors) &&
    payload.errors.every(
      (item) => isRecord(item) && typeof item.detail === 'string'
    )
  )
}

function getErrorMessage(payload: unknown): string {
  if (isApiErrorResponse(payload) && payload.errors.length > 0) {
    return payload.errors[0].detail
  }

  return 'Invalid email or password.'
}

export interface UseAuthResult {
  token: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<boolean>
  logout: () => void
  isLoading: boolean
  error: string | null
}

export function useAuth(): UseAuthResult {
  const [token, setToken] = useState<string | null>(() =>
    localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
  )
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const login = useCallback(async (email: string, password: string) => {
    setIsLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/v1/auth', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      })

      const payload: unknown = await response.json()

      if (!response.ok) {
        setError(getErrorMessage(payload))
        return false
      }

      if (!isAuthSuccessResponse(payload)) {
        setError('Authentication response was invalid.')
        return false
      }

      localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, payload.token)
      setToken(payload.token)
      return true
    } catch {
      setError('Unable to log in. Please try again.')
      return false
    } finally {
      setIsLoading(false)
    }
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY)
    setToken(null)
    setError(null)
  }, [])

  const isAuthenticated = useMemo(() => token !== null, [token])

  return { token, isAuthenticated, login, logout, isLoading, error }
}
