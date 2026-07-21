import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isCitiesResponse,
  type City,
  type CitiesResponse,
} from '../lib/api-types'

interface UseCitiesResult {
  cities: readonly City[]
  isLoading: boolean
  error: string | null
}

export function useCities(): UseCitiesResult {
  const [cities, setCities] = useState<readonly City[]>([])
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

      const data: CitiesResponse = payload
      setCities(data.cities)
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
