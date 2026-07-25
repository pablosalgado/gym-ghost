import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useSchedule } from './useSchedule'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

const AUTH_TOKEN = 'test-token-123'

const MOCK_SCHEDULE_RESPONSE = {
  schedule: [
    { id: 1, activity_name: 'Yoga', activity_id: 10, facility_id: 5, starts_at: '2026-07-20T12:00:00.000Z' },
    { id: 2, activity_name: 'Spinning', activity_id: 20, facility_id: 5, starts_at: '2026-07-20T14:00:00.000Z' },
  ],
  class_types: [
    { id: 10, name: 'Yoga' },
    { id: 20, name: 'Spinning' },
  ],
}

const MAPPED_SESSIONS = [
  { id: '1', facilityId: 5, activityName: 'Yoga', activityId: 10, startsAt: '2026-07-20T12:00:00.000Z' },
  { id: '2', facilityId: 5, activityName: 'Spinning', activityId: 20, startsAt: '2026-07-20T14:00:00.000Z' },
]

const MOCK_EMPTY_RESPONSE = { schedule: [], class_types: [] }

const MOCK_SCHEDULE_ITEMS = [
  { id: 1, activity_name: 'Yoga', activity_id: 10, facility_id: 9, starts_at: '2026-07-23T10:00:00.000Z' },
  { id: 2, activity_name: 'Spinning', activity_id: 20, facility_id: 9, starts_at: '2026-07-23T11:00:00.000Z' },
]

const MOCK_CLASS_TYPES = [
  { id: 10, name: 'Yoga' },
  { id: 20, name: 'Spinning' },
]

const MOCK_FULL_RESPONSE = { schedule: MOCK_SCHEDULE_ITEMS, class_types: MOCK_CLASS_TYPES }

describe('useSchedule', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  function stubFetch(responses: Array<{ ok: boolean; status?: number; json: () => unknown }>) {
    const fetchMock = vi.fn()
    for (const response of responses) {
      fetchMock.mockResolvedValueOnce(response)
    }
    vi.stubGlobal('fetch', fetchMock)
    return fetchMock
  }

  it('fetches schedule for a given date and facility', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(MOCK_SCHEDULE_RESPONSE),
      })
    )

    const { result } = renderHook(() => useSchedule('2026-07-20', 5))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.sessions).toEqual(MAPPED_SESSIONS)
    expect(result.current.classTypes).toEqual(MOCK_SCHEDULE_RESPONSE.class_types)
    expect(result.current.error).toBeNull()
    expect(fetch).toHaveBeenCalledWith(
      '/api/v1/schedule?date=2026-07-20&facility_id=5',
      { headers: { Authorization: `Bearer ${AUTH_TOKEN}` } },
    )
  })

  it('fetches without facility filter when facilityId is omitted', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(MOCK_SCHEDULE_RESPONSE),
      })
    )

    const { result } = renderHook(() => useSchedule('2026-07-20'))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.sessions).toEqual(MAPPED_SESSIONS)
    expect(fetch).toHaveBeenCalledWith(
      '/api/v1/schedule?date=2026-07-20',
      { headers: { Authorization: `Bearer ${AUTH_TOKEN}` } },
    )
  })

  it('refetches when facilityId changes', async () => {
    const fetchMock = vi.fn()

    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(MOCK_SCHEDULE_RESPONSE),
    })
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({
        schedule: [],
        class_types: [{ id: 30, name: 'Boxing' }],
      }),
    })

    vi.stubGlobal('fetch', fetchMock)

    const { result, rerender } = renderHook(
      ({ facilityId }: { facilityId?: number }) =>
        useSchedule('2026-07-20', facilityId),
      { initialProps: { facilityId: 5 } },
    )

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    rerender({ facilityId: 9 })

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock).toHaveBeenLastCalledWith(
      '/api/v1/schedule?date=2026-07-20&facility_id=9',
      { headers: { Authorization: `Bearer ${AUTH_TOKEN}` } },
    )
  })

  it('refetches when date changes', async () => {
    const fetchMock = vi.fn()

    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(MOCK_SCHEDULE_RESPONSE),
    })
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ schedule: [], class_types: [] }),
    })

    vi.stubGlobal('fetch', fetchMock)

    const { result, rerender } = renderHook(
      (dateKey: string) => useSchedule(dateKey),
      { initialProps: '2026-07-20' },
    )

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    rerender('2026-07-21')

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock).toHaveBeenLastCalledWith(
      '/api/v1/schedule?date=2026-07-21',
      { headers: { Authorization: `Bearer ${AUTH_TOKEN}` } },
    )
  })

  it('returns empty arrays on non-ok response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
        json: () => Promise.resolve({}),
      })
    )

    const { result } = renderHook(() => useSchedule('2026-07-20', 5))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.sessions).toEqual([])
    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Request failed: 500')
  })

  it('returns empty arrays on network error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

    const { result } = renderHook(() => useSchedule('2026-07-20', 5))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.sessions).toEqual([])
    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Network error')
  })

  it('shows loading state while fetching', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(MOCK_SCHEDULE_RESPONSE),
      })
    )

    const { result } = renderHook(() => useSchedule('2026-07-20', 5))

    expect(result.current.isLoading).toBe(true)
    expect(result.current.sessions).toEqual([])
    expect(result.current.classTypes).toEqual([])

    await waitFor(() => expect(result.current.isLoading).toBe(false))
  })

  it('returns empty arrays when no auth token is present', async () => {
    localStorage.clear()

    const { result } = renderHook(() => useSchedule('2026-07-20', 5))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.sessions).toEqual([])
    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Not authenticated')
  })

  it('returns empty arrays on malformed response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ unexpected: true }),
      })
    )

    const { result } = renderHook(() => useSchedule('2026-07-20', 5))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.sessions).toEqual([])
    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Invalid response format')
  })

  describe('empty response polling', () => {
    beforeEach(() => {
      vi.useFakeTimers({ shouldAdvanceTime: true })
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('enters polling state when response is empty', async () => {
      stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
      ])

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))

      expect(result.current.sessions).toEqual([])
      expect(result.current.classTypes).toEqual([])
      expect(result.current.isBackgroundLoading).toBe(true)
      expect(result.current.retryCount).toBe(0)
    })

    it('stops polling when data arrives on retry', async () => {
      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
      ])

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(fetchMock).toHaveBeenCalledTimes(1)

      vi.advanceTimersByTime(3000)
      await waitFor(() => expect(result.current.sessions.length).toBeGreaterThan(0))

      expect(result.current.isBackgroundLoading).toBe(false)
      expect(fetchMock).toHaveBeenCalledTimes(2)
    })

    it('retries with exponential backoff: 3s, 6s, 12s', async () => {
      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
      ])

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(fetchMock).toHaveBeenCalledTimes(1)
      expect(result.current.retryCount).toBe(0)

      vi.advanceTimersByTime(3000)
      await waitFor(() => expect(result.current.retryCount).toBe(1))
      expect(fetchMock).toHaveBeenCalledTimes(2)

      vi.advanceTimersByTime(6000)
      await waitFor(() => expect(result.current.retryCount).toBe(2))
      expect(fetchMock).toHaveBeenCalledTimes(3)

      vi.advanceTimersByTime(12000)
      await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(4))

      expect(result.current.sessions.length).toBeGreaterThan(0)
      expect(result.current.isBackgroundLoading).toBe(false)
    })

    it('stops polling after max retries (3) exhausted', async () => {
      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
      ])

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.retryCount).toBe(0)

      vi.advanceTimersByTime(3000)
      await waitFor(() => expect(result.current.retryCount).toBe(1))
      expect(fetchMock).toHaveBeenCalledTimes(2)

      vi.advanceTimersByTime(6000)
      await waitFor(() => expect(result.current.retryCount).toBe(2))
      expect(fetchMock).toHaveBeenCalledTimes(3)

      vi.advanceTimersByTime(12000)
      await waitFor(() => expect(result.current.retryCount).toBe(3))
      expect(fetchMock).toHaveBeenCalledTimes(4)
      expect(result.current.isBackgroundLoading).toBe(false)

      vi.advanceTimersByTime(30000)
      expect(fetchMock).toHaveBeenCalledTimes(4)
    })

    it('stops polling on non-ok response', async () => {
      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: false, status: 500, json: () => Promise.resolve({}) },
      ])

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(true)

      vi.advanceTimersByTime(3000)
      await waitFor(() => expect(result.current.isBackgroundLoading).toBe(false))
      expect(result.current.error).toBe('Request failed: 500')
      expect(result.current.sessions).toEqual([])
    })

    it('stops polling on network error', async () => {
      const fetchMock = vi.fn()
      fetchMock.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(MOCK_EMPTY_RESPONSE),
      })
      fetchMock.mockRejectedValueOnce(new Error('Network down'))
      vi.stubGlobal('fetch', fetchMock)

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(true)

      vi.advanceTimersByTime(3000)
      await waitFor(() => expect(result.current.isBackgroundLoading).toBe(false))
      expect(result.current.error).toBe('Network error')
    })
  })

  describe('param changes', () => {
    it('restarts fetch when date changes (no polling)', async () => {
      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
      ])

      const { result, rerender } = renderHook(
        (props: { date: string; facilityId?: number }) =>
          useSchedule(props.date, props.facilityId),
        { initialProps: { date: '2026-07-23', facilityId: 9 } },
      )

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(fetchMock).toHaveBeenCalledTimes(1)

      rerender({ date: '2026-07-24', facilityId: 9 })

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(fetchMock).toHaveBeenCalledTimes(2)
      expect(fetchMock).toHaveBeenLastCalledWith(
        '/api/v1/schedule?date=2026-07-24&facility_id=9',
        { headers: { Authorization: `Bearer ${AUTH_TOKEN}` } },
      )
    })

    it('cancels in-flight polling when date changes', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
      ])

      const { result, rerender } = renderHook(
        (props: { date: string; facilityId?: number }) =>
          useSchedule(props.date, props.facilityId),
        { initialProps: { date: '2026-07-23', facilityId: 9 } },
      )

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(true)
      expect(fetchMock).toHaveBeenCalledTimes(1)

      rerender({ date: '2026-07-24', facilityId: 9 })

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(false)

      expect(fetchMock).toHaveBeenCalledTimes(2)
      expect(fetchMock).toHaveBeenLastCalledWith(
        '/api/v1/schedule?date=2026-07-24&facility_id=9',
        { headers: { Authorization: `Bearer ${AUTH_TOKEN}` } },
      )

      vi.useRealTimers()
    })

    it('cancels in-flight polling when facilityId changes', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
      ])

      const { result, rerender } = renderHook(
        (props: { date: string; facilityId?: number }) =>
          useSchedule(props.date, props.facilityId),
        { initialProps: { date: '2026-07-23', facilityId: 9 } },
      )

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(true)
      expect(fetchMock).toHaveBeenCalledTimes(1)

      rerender({ date: '2026-07-23', facilityId: 10 })

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(false)
      expect(fetchMock).toHaveBeenCalledTimes(2)

      vi.useRealTimers()
    })
  })

  describe('manualRetry', () => {
    it('resets state and re-fetches after exhaustion', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
        { ok: true, json: () => Promise.resolve(MOCK_FULL_RESPONSE) },
      ])

      const { result } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      vi.advanceTimersByTime(3000)
      await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
      vi.advanceTimersByTime(6000)
      await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
      vi.advanceTimersByTime(12000)
      await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(4))

      expect(result.current.retryCount).toBe(3)
      expect(result.current.isBackgroundLoading).toBe(false)

      result.current.manualRetry()

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.sessions.length).toBeGreaterThan(0)
      expect(fetchMock).toHaveBeenCalledTimes(5)

      vi.useRealTimers()
    })
  })

  describe('cleanup', () => {
    it('cancels timer on unmount during polling', async () => {
      vi.useFakeTimers({ shouldAdvanceTime: true })

      const fetchMock = stubFetch([
        { ok: true, json: () => Promise.resolve(MOCK_EMPTY_RESPONSE) },
      ])

      const { result, unmount } = renderHook(() => useSchedule('2026-07-23'))

      await waitFor(() => expect(result.current.isLoading).toBe(false))
      expect(result.current.isBackgroundLoading).toBe(true)
      expect(fetchMock).toHaveBeenCalledTimes(1)

      unmount()

      vi.advanceTimersByTime(30000)
      expect(fetchMock).toHaveBeenCalledTimes(1)

      vi.useRealTimers()
    })
  })
})
