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
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchFacilities = useCallback(async () => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const params = cityId !== undefined ? `?city_id=${cityId}` : ''
      const response = await fetch(`/api/v1/facilities${params}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        setFacilities([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (!isFacilitiesResponse(payload)) {
        setFacilities([])
        setError('Invalid response format')
        return
      }

      const data: FacilitiesResponse = payload
      setFacilities(data.facilities)
    } catch {
      setFacilities([])
      setError('Network error')
    } finally {
      setIsLoading(false)
    }
  }, [cityId])

  useEffect(() => {
    fetchFacilities()
  }, [fetchFacilities])

  return { facilities, isLoading, error }
}
