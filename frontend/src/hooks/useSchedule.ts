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

interface ScheduleQuery {
  dateKey: string
  cityId?: number
  facilityId?: number
}

interface ScheduleLifecycle {
  query: ScheduleQuery
  controller: AbortController
  pollTimer: ReturnType<typeof setTimeout> | null
  retryCount: number
  active: boolean
}

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
    bookingRequest: item.booking_request,
  }
}

function queriesMatch(left: ScheduleQuery, right: ScheduleQuery): boolean {
  return (
    left.dateKey === right.dateKey &&
    left.cityId === right.cityId &&
    left.facilityId === right.facilityId
  )
}

export function useSchedule(
  dateKey: string,
  cityId?: number,
  facilityId?: number,
): UseScheduleResult {
  const [schedule, setSchedule] = useState<readonly ScheduleItem[]>([])
  const [classTypes, setClassTypes] = useState<readonly ClassType[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isBackgroundLoading, setIsBackgroundLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [retryCount, setRetryCount] = useState(0)

  const queryRef = useRef<ScheduleQuery>({ dateKey, cityId, facilityId })
  const lifecycleRef = useRef<ScheduleLifecycle | null>(null)
  queryRef.current = { dateKey, cityId, facilityId }

  const cancelLifecycle = useCallback((lifecycle: ScheduleLifecycle) => {
    lifecycle.active = false
    lifecycle.controller.abort()

    if (lifecycle.pollTimer !== null) {
      clearTimeout(lifecycle.pollTimer)
      lifecycle.pollTimer = null
    }
  }, [])

  const cancelCurrentLifecycle = useCallback(() => {
    const lifecycle = lifecycleRef.current
    if (lifecycle === null) return

    cancelLifecycle(lifecycle)
    lifecycleRef.current = null
  }, [cancelLifecycle])

  const isCurrentLifecycle = useCallback((lifecycle: ScheduleLifecycle) => {
    return (
      lifecycle.active &&
      lifecycleRef.current === lifecycle &&
      !lifecycle.controller.signal.aborted &&
      queriesMatch(lifecycle.query, queryRef.current)
    )
  }, [])

  const startLifecycle = useCallback(
    (query: ScheduleQuery) => {
      cancelCurrentLifecycle()

      const lifecycle: ScheduleLifecycle = {
        query,
        controller: new AbortController(),
        pollTimer: null,
        retryCount: 0,
        active: true,
      }
      lifecycleRef.current = lifecycle

      setSchedule([])
      setClassTypes([])
      setRetryCount(0)
      setIsLoading(true)
      setIsBackgroundLoading(false)
      setError(null)

      if (query.cityId === undefined || query.facilityId === undefined) {
        setIsLoading(false)
        return
      }

      const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
      if (!token) {
        setError('Not authenticated')
        setIsLoading(false)
        return
      }

      const fetchSchedule = async (isRetry: boolean): Promise<void> => {
        if (!isCurrentLifecycle(lifecycle)) return

        try {
          const params = new URLSearchParams({
            date: query.dateKey,
            city_id: String(query.cityId),
            facility_id: String(query.facilityId),
          })

          const response = await fetch(
            `/api/v1/schedule?${params.toString()}`,
            {
              headers: {
                Authorization: `Bearer ${token}`,
                'Cache-Control': 'no-store',
              },
              signal: lifecycle.controller.signal,
            },
          )

          if (!isCurrentLifecycle(lifecycle)) return

          if (!response.ok) {
            setSchedule([])
            setClassTypes([])
            setError(`Request failed: ${response.status}`)
            setIsLoading(false)
            setIsBackgroundLoading(false)
            return
          }

          const payload: unknown = await response.json()

          if (!isCurrentLifecycle(lifecycle)) return

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

          setSchedule([])
          setClassTypes(data.class_types)
          setIsLoading(false)

          lifecycle.retryCount = isRetry ? lifecycle.retryCount + 1 : 0
          setRetryCount(lifecycle.retryCount)

          if (lifecycle.retryCount >= MAX_RETRIES) {
            setIsBackgroundLoading(false)
            return
          }

          setIsBackgroundLoading(true)

          const delay = RETRY_DELAYS_MS[lifecycle.retryCount]
          lifecycle.pollTimer = setTimeout(() => {
            lifecycle.pollTimer = null
            void fetchSchedule(true)
          }, delay)
        } catch {
          if (!isCurrentLifecycle(lifecycle)) return
          setSchedule([])
          setClassTypes([])
          setError('Network error')
          setIsLoading(false)
          setIsBackgroundLoading(false)
        }
      }

      void fetchSchedule(false)
    },
    [cancelCurrentLifecycle, isCurrentLifecycle],
  )

  const manualRetry = useCallback(() => {
    startLifecycle(queryRef.current)
  }, [startLifecycle])

  useEffect(() => {
    startLifecycle({ dateKey, cityId, facilityId })
    return cancelCurrentLifecycle
  }, [cancelCurrentLifecycle, cityId, dateKey, facilityId, startLifecycle])

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
