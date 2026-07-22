import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isScheduleResponse,
  type ScheduleItem,
  type ScheduleResponse,
} from '../lib/api-types'
import type { Session } from '../features/schedule/types'

function toSession(item: ScheduleItem): Session {
  return {
    id: String(item.id),
    facilityId: item.facility_id,
    activityName: item.name,
    startsAt: item.starts_at,
    durationMinutes: item.duration_minutes,
  }
}

interface UseScheduleResult {
  sessions: readonly Session[]
  isLoading: boolean
  error: string | null
}

export function useSchedule(
  dateKey: string,
  facilityId?: number,
): UseScheduleResult {
  const [sessions, setSessions] = useState<readonly Session[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchSchedule = useCallback(async () => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      setIsLoading(false)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const params = new URLSearchParams({ date: dateKey })
      if (facilityId !== undefined) {
        params.set('facility_id', String(facilityId))
      }

      const response = await fetch(`/api/v1/schedule?${params}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })

      if (!response.ok) {
        setSessions([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (!isScheduleResponse(payload)) {
        setSessions([])
        setError('Invalid response format')
        return
      }

      const data: ScheduleResponse = payload
      setSessions(data.schedule.map(toSession))
    } catch {
      setSessions([])
      setError('Network error')
    } finally {
      setIsLoading(false)
    }
  }, [dateKey, facilityId])

  useEffect(() => {
    fetchSchedule()
  }, [fetchSchedule])

  return { sessions, isLoading, error }
}
