import { useEffect, useRef, useState } from 'react'
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

interface FacilitiesState {
  cityId: number | undefined
  facilities: readonly Facility[]
  isLoading: boolean
  error: string | null
}

export function useFacilities(cityId?: number): UseFacilitiesResult {
  const [state, setState] = useState<FacilitiesState>(() => ({
    cityId,
    facilities: [],
    isLoading: cityId !== undefined,
    error: null,
  }))
  const requestIdRef = useRef(0)

  useEffect(() => {
    const requestId = requestIdRef.current + 1
    requestIdRef.current = requestId
    let isActive = true
    const controller = new AbortController()

    const isCurrentRequest = () => isActive && requestIdRef.current === requestId
    const updateState = (
      facilities: readonly Facility[],
      isLoading: boolean,
      error: string | null,
    ) => {
      if (!isCurrentRequest()) return
      setState({ cityId, facilities, isLoading, error })
    }

    updateState([], cityId !== undefined, null)

    const cleanup = () => {
      isActive = false
      controller.abort()
    }

    if (cityId === undefined) {
      return cleanup
    }

    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      updateState([], false, 'Not authenticated')
      return cleanup
    }

    async function loadFacilities() {
      try {
        const params = `?city_id=${cityId}`
        const response = await fetch(`/api/v1/facilities${params}`, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
          signal: controller.signal,
        })

        if (!isCurrentRequest()) return

        if (!response.ok) {
          updateState([], false, `Request failed: ${response.status}`)
          return
        }

        const payload: unknown = await response.json()

        if (!isCurrentRequest()) return

        if (!isFacilitiesResponse(payload)) {
          updateState([], false, 'Invalid response format')
          return
        }

        const data: FacilitiesResponse = payload
        updateState(data.facilities, false, null)
      } catch {
        if (!isCurrentRequest()) return
        updateState([], false, 'Network error')
      }
    }

    void loadFacilities()

    return cleanup
  }, [cityId])

  const isCurrentCity = state.cityId === cityId

  return {
    facilities: isCurrentCity ? state.facilities : [],
    isLoading: cityId !== undefined && (!isCurrentCity || state.isLoading),
    error: isCurrentCity ? state.error : null,
  }
}
