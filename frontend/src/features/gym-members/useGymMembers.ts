import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from '../../hooks/useAuth'
import {
  isGymMembersResponse,
  type GymMember,
} from '../../lib/api-types'

interface UseGymMembersResult {
  members: readonly GymMember[]
  isLoading: boolean
  error: string | null
}

export function useGymMembers(): UseGymMembersResult {
  const [members, setMembers] = useState<readonly GymMember[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchGymMembers = useCallback(async () => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/v1/gym_members', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        setMembers([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (!isGymMembersResponse(payload)) {
        setMembers([])
        setError('Invalid response format')
        return
      }

      setMembers(payload.gym_members)
    } catch {
      setMembers([])
      setError('Network error')
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchGymMembers()
  }, [fetchGymMembers])

  return { members, isLoading, error }
}
