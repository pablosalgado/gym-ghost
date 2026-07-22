import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isClassTypesResponse,
  type ClassType,
  type ClassTypesResponse,
} from '../lib/api-types'

interface UseClassTypesResult {
  classTypes: readonly ClassType[]
  isLoading: boolean
  error: string | null
}

export function useClassTypes(facilityId?: number): UseClassTypesResult {
  const [classTypes, setClassTypes] = useState<readonly ClassType[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchClassTypes = useCallback(async () => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const params = facilityId !== undefined ? `?facility_id=${facilityId}` : ''
      const response = await fetch(`/api/v1/activities${params}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        setClassTypes([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (!isClassTypesResponse(payload)) {
        setClassTypes([])
        setError('Invalid response format')
        return
      }

      const data: ClassTypesResponse = payload
      setClassTypes(data.activities)
    } catch {
      setClassTypes([])
      setError('Network error')
    } finally {
      setIsLoading(false)
    }
  }, [facilityId])

  useEffect(() => {
    fetchClassTypes()
  }, [fetchClassTypes])

  return { classTypes, isLoading, error }
}
