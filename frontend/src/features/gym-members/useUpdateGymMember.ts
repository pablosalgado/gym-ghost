import { useCallback, useEffect, useRef, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from '../../hooks/useAuth'
import {
  isGymMemberResponse,
  isErrorResponse,
  type GymMember,
} from '../../lib/api-types'

export interface UseUpdateGymMemberResult {
  updatePassword: (memberId: number, password: string) => Promise<boolean>
  isLoading: boolean
  error: string | null
  updatedMember: GymMember | null
}

export function useUpdateGymMember(): UseUpdateGymMemberResult {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [updatedMember, setUpdatedMember] = useState<GymMember | null>(null)
  const cancelledRef = useRef(false)

  useEffect(() => {
    return () => {
      cancelledRef.current = true
    }
  }, [])

  const updatePassword = useCallback(async (memberId: number, password: string): Promise<boolean> => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      return false
    }

    cancelledRef.current = false
    setIsLoading(true)
    setError(null)
    setUpdatedMember(null)

    try {
      const response = await fetch(`/api/v1/gym_members/${memberId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ password }),
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

      if (!isGymMemberResponse(payload)) {
        setError('Invalid response format')
        return false
      }

      setUpdatedMember(payload.gym_member)
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

  return { updatePassword, isLoading, error, updatedMember }
}
