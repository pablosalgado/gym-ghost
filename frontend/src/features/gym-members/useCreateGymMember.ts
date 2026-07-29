import { useCallback, useEffect, useRef, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from '../../hooks/useAuth'
import {
  isCreateGymMemberResponse,
  isErrorResponse,
  type CreateGymMemberResponse,
} from '../../lib/api-types'

export interface UseCreateGymMemberResult {
  create: (email: string, password: string) => Promise<boolean>
  isLoading: boolean
  error: string | null
}

export function useCreateGymMember(): UseCreateGymMemberResult {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const cancelledRef = useRef(false)

  useEffect(() => {
    return () => {
      cancelledRef.current = true
    }
  }, [])

  const create = useCallback(async (email: string, password: string): Promise<boolean> => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      return false
    }

    cancelledRef.current = false
    setIsLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/v1/gym_members', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ email, password }),
      })

      if (cancelledRef.current) return false

      const payload: unknown = await response.json()

      if (cancelledRef.current) return false

      if (!response.ok) {
        if (isErrorResponse(payload) && payload.errors.length > 0) {
          setError(payload.errors[0].detail)
        } else {
          setError(`Request failed: ${response.status}`)
        }
        return false
      }

      if (!isCreateGymMemberResponse(payload)) {
        setError('Invalid response format')
        return false
      }

      return true
    } catch {
      if (cancelledRef.current) return false
      setError('Network error')
      return false
    } finally {
      if (!cancelledRef.current) {
        setIsLoading(false)
      }
    }
  }, [])

  return { create, isLoading, error }
}
