import { useCallback, useMemo, useState } from 'react'
import {
  isLoginResponse,
  isErrorResponse,
  type ErrorResponse,
} from '../lib/api-types'

export const AUTH_TOKEN_STORAGE_KEY = 'gym-ghost-auth-token'

export type AuthErrorKey =
  | 'auth.invalidCredentials'
  | 'auth.loginUnavailable'
  | 'auth.invalidAuthResponse'

export type AuthError =
  | { kind: 'server'; detail: string }
  | { kind: 'key'; key: AuthErrorKey }

function getAuthError(payload: unknown): AuthError {
  if (isErrorResponse(payload) && payload.errors.length > 0) {
    return { kind: 'server', detail: payload.errors[0].detail }
  }

  return { kind: 'key', key: 'auth.invalidCredentials' }
}

export interface UseAuthResult {
  token: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<boolean>
  logout: () => void
  isLoading: boolean
  error: AuthError | null
}

export function useAuth(): UseAuthResult {
  const [token, setToken] = useState<string | null>(() =>
    localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
  )
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<AuthError | null>(null)

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
        setError(getAuthError(payload))
        return false
      }

      if (!isLoginResponse(payload)) {
        setError({ kind: 'key', key: 'auth.invalidAuthResponse' })
        return false
      }

      localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, payload.token)
      setToken(payload.token)
      return true
    } catch {
      setError({ kind: 'key', key: 'auth.loginUnavailable' })
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
