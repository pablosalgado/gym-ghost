import { useCallback, useEffect, useRef, useState } from 'react'
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

  const cancelledRef = useRef(false)

  useEffect(() => {
    return () => {
      cancelledRef.current = true
    }
  }, [])

  const fetchCities = useCallback(async () => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    cancelledRef.current = false
    setIsLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/v1/cities', {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (cancelledRef.current) return

      if (!response.ok) {
        setCities([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (cancelledRef.current) return

      if (!isCitiesResponse(payload)) {
        setCities([])
        setError('Invalid response format')
        return
      }

      const data: CitiesResponse = payload
      setCities(data.cities)
    } catch {
      if (cancelledRef.current) return
      setCities([])
      setError('Network error')
    } finally {
      if (!cancelledRef.current) {
        setIsLoading(false)
      }
    }
  }, [])

  useEffect(() => {
    cancelledRef.current = false
    fetchCities()

    return () => {
      cancelledRef.current = true
    }
  }, [fetchCities])

  return { cities, isLoading, error }
}
