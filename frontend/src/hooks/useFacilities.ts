import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isFacilitiesResponse,
  type Facility,
  type FacilitiesResponse,
} from '../lib/api-types'

interface UseFacilitiesResult {
  facilities: readonly Facility[]
  isLoading: boolean
  error: string | null
}

export function useFacilities(cityId?: number): UseFacilitiesResult {
  const [facilities, setFacilities] = useState<readonly Facility[]>([])
  const [isLoading, setIsLoading] = useState(cityId !== undefined)
  const [error, setError] = useState<string | null>(null)

  const fetchFacilities = useCallback(async (isCancelled: () => boolean) => {
    if (cityId === undefined) {
      setFacilities([])
      setError(null)
      setIsLoading(false)
      return
    }

    setFacilities([])
    setIsLoading(true)
    setError(null)

    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    try {
      const params = `?city_id=${cityId}`
      const response = await fetch(`/api/v1/facilities${params}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (isCancelled()) return

      if (!response.ok) {
        setFacilities([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (isCancelled()) return

      if (!isFacilitiesResponse(payload)) {
        setFacilities([])
        setError('Invalid response format')
        return
      }

      const data: FacilitiesResponse = payload
      setFacilities(data.facilities)
    } catch {
      if (isCancelled()) return
      setFacilities([])
      setError('Network error')
    } finally {
      if (!isCancelled()) {
        setIsLoading(false)
      }
    }
  }, [cityId])

  useEffect(() => {
    let cancelled = false
    void fetchFacilities(() => cancelled)

    return () => {
      cancelled = true
    }
  }, [fetchFacilities])

  return { facilities, isLoading, error }
}
