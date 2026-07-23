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

describe('useSchedule', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

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
})
