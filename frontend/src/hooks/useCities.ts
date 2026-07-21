import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

export interface ApiCity {
  id: number
  city_name: string
}

interface UseCitiesResult {
  cities: readonly ApiCity[]
  isLoading: boolean
  error: string | null
}

interface CitiesResponse {
  cities: ApiCity[]
}

function isCitiesResponse(payload: unknown): payload is CitiesResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'cities' in payload &&
    Array.isArray((payload as Record<string, unknown>).cities)
  )
}

export function useCities(): UseCitiesResult {
  const [cities, setCities] = useState<readonly ApiCity[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchCities = useCallback(async () => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/v1/cities', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        setCities([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (!isCitiesResponse(payload)) {
        setCities([])
        setError('Invalid response format')
        return
      }

      setCities(payload.cities)
    } catch {
      setCities([])
      setError('Network error')
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchCities()
  }, [fetchCities])

  return { cities, isLoading, error }
}
