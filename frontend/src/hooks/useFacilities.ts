import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

export interface ApiFacility {
  id: number
  display_name: string
  city_id: number
}

interface UseFacilitiesResult {
  facilities: readonly ApiFacility[]
  isLoading: boolean
  error: string | null
}

interface FacilitiesResponse {
  facilities: ApiFacility[]
}

function isFacilitiesResponse(payload: unknown): payload is FacilitiesResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'facilities' in payload &&
    Array.isArray((payload as Record<string, unknown>).facilities)
  )
}

export function useFacilities(cityId?: number): UseFacilitiesResult {
  const [facilities, setFacilities] = useState<readonly ApiFacility[]>([])
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

      setFacilities(payload.facilities)
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
