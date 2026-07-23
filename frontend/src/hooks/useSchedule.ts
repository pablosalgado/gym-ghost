import { useCallback, useEffect, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isScheduleResponse,
  type ClassType,
  type ScheduleItem,
  type ScheduleResponse,
} from '../lib/api-types'
import type { Session } from '../features/schedule/types'

interface UseScheduleResult {
  sessions: readonly Session[]
  classTypes: readonly ClassType[]
  isLoading: boolean
  error: string | null
}

function toSession(item: ScheduleItem): Session {
  return {
    id: String(item.id),
    facilityId: item.facility_id,
    activityName: item.activity_name,
    activityId: item.activity_id,
    startsAt: item.starts_at,
  }
}

export function useSchedule(dateKey: string, facilityId?: number): UseScheduleResult {
  const [sessions, setSessions] = useState<readonly Session[]>([])
  const [classTypes, setClassTypes] = useState<readonly ClassType[]>([])
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
        setClassTypes([])
        setError(`Request failed: ${response.status}`)
        return
      }

      const payload: unknown = await response.json()

      if (!isScheduleResponse(payload)) {
        setSessions([])
        setClassTypes([])
        setError('Invalid response format')
        return
      }

      const data: ScheduleResponse = payload
      setSessions(data.schedule.map(toSession))
      setClassTypes(data.class_types)
    } catch {
      setSessions([])
      setClassTypes([])
      setError('Network error')
    } finally {
      setIsLoading(false)
    }
  }, [dateKey, facilityId])

  useEffect(() => {
    fetchSchedule()
  }, [fetchSchedule])

  return { sessions, classTypes, isLoading, error }
}
