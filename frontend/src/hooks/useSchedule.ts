import { useCallback, useEffect, useRef, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isScheduleResponse,
  type ClassType,
  type ScheduleItem,
  type ScheduleResponse,
} from '../lib/api-types'
import type { Session } from '../features/schedule/types'

const MAX_RETRIES = 3
const RETRY_DELAYS_MS = [3000, 6000, 12000]

export interface UseScheduleResult {
  sessions: readonly Session[]
  classTypes: readonly ClassType[]
  isLoading: boolean
  isBackgroundLoading: boolean
  error: string | null
  retryCount: number
  maxRetries: number
  manualRetry: () => void
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

export function useSchedule(
  dateKey: string,
  facilityId?: number,
): UseScheduleResult {
  const [schedule, setSchedule] = useState<readonly ScheduleItem[]>([])
  const [classTypes, setClassTypes] = useState<readonly ClassType[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isBackgroundLoading, setIsBackgroundLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [retryCount, setRetryCount] = useState(0)

  const dateKeyRef = useRef(dateKey)
  const facilityIdRef = useRef(facilityId)
  const retryCountRef = useRef(0)
  const cancelledRef = useRef(false)
  const pollTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // Keep refs in sync so setTimeout callbacks read fresh values.
  dateKeyRef.current = dateKey
  facilityIdRef.current = facilityId

  const clearPollTimer = useCallback(() => {
    if (pollTimerRef.current !== null) {
      clearTimeout(pollTimerRef.current)
      pollTimerRef.current = null
    }
  }, [])

  const doFetch = useCallback(
    async (isRetry: boolean) => {
      const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
      if (!token) {
        setError('Not authenticated')
        setIsLoading(false)
        setIsBackgroundLoading(false)
        return
      }

      if (!isRetry) {
        setIsLoading(true)
        setError(null)
      }

      try {
        const params = new URLSearchParams({ date: dateKeyRef.current })
        if (facilityIdRef.current !== undefined) {
          params.set('facility_id', String(facilityIdRef.current))
        }

        const response = await fetch(
          `/api/v1/schedule?${params.toString()}`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          },
        )

        if (cancelledRef.current) return

        if (!response.ok) {
          setSchedule([])
          setClassTypes([])
          setError(`Request failed: ${response.status}`)
          setIsLoading(false)
          setIsBackgroundLoading(false)
          return
        }

        const payload: unknown = await response.json()

        if (cancelledRef.current) return

        if (!isScheduleResponse(payload)) {
          setSchedule([])
          setClassTypes([])
          setError('Invalid response format')
          setIsLoading(false)
          setIsBackgroundLoading(false)
          return
        }

        const data: ScheduleResponse = payload

        if (data.schedule.length > 0) {
          setSchedule(data.schedule)
          setClassTypes(data.class_types)
          setError(null)
          setIsLoading(false)
          setIsBackgroundLoading(false)
          return
        }

        // Empty schedule response — may need to retry.
        setSchedule([])
        setClassTypes(data.class_types)
        setIsLoading(false)

        const nextRetry = isRetry ? retryCountRef.current + 1 : 0
        retryCountRef.current = nextRetry
        setRetryCount(nextRetry)

        if (nextRetry >= MAX_RETRIES) {
          setIsBackgroundLoading(false)
          return
        }

        setIsBackgroundLoading(true)

        const delay = RETRY_DELAYS_MS[nextRetry]
        pollTimerRef.current = setTimeout(() => {
          doFetch(true)
        }, delay)
      } catch {
        if (cancelledRef.current) return
        setSchedule([])
        setClassTypes([])
        setError('Network error')
        setIsLoading(false)
        setIsBackgroundLoading(false)
      }
    },
    [],
  )

  const manualRetry = useCallback(() => {
    clearPollTimer()
    cancelledRef.current = false
    retryCountRef.current = 0
    setRetryCount(0)
    setSchedule([])
    setClassTypes([])
    setError(null)
    setIsLoading(true)
    setIsBackgroundLoading(false)
    doFetch(false)
  }, [clearPollTimer, doFetch])

  useEffect(() => {
    cancelledRef.current = false
    clearPollTimer()
    retryCountRef.current = 0
    setRetryCount(0)
    setSchedule([])
    setClassTypes([])
    setIsLoading(true)
    setIsBackgroundLoading(false)
    setError(null)
    doFetch(false)

    return () => {
      cancelledRef.current = true
      clearPollTimer()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dateKey, facilityId])

  const sessions = schedule.map(toSession)

  return {
    sessions,
    classTypes,
    isLoading,
    isBackgroundLoading,
    error,
    retryCount,
    maxRetries: MAX_RETRIES,
    manualRetry,
  }
}
