import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useFacilities } from './useFacilities'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

const AUTH_TOKEN = 'test-token-123'

const MOCK_FACILITIES = [
  { id: 1, display_name: 'Chapinero', city_id: 1 },
  { id: 2, display_name: 'Usaquén', city_id: 1 },
]

describe('useFacilities', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('fetches all facilities when no cityId is provided', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ facilities: MOCK_FACILITIES }),
      })
    )

    const { result } = renderHook(() => useFacilities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual(MOCK_FACILITIES)
    expect(result.current.error).toBeNull()
    expect(fetch).toHaveBeenCalledWith('/api/v1/facilities', {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
    })
  })

  it('filters facilities by cityId when provided', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ facilities: [MOCK_FACILITIES[0]] }),
      })
    )

    const { result } = renderHook(() => useFacilities(1))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([MOCK_FACILITIES[0]])
    expect(fetch).toHaveBeenCalledWith('/api/v1/facilities?city_id=1', {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
    })
  })

  it('re-fetches when cityId changes', async () => {
    const fetchMock = vi.fn()

    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ facilities: [MOCK_FACILITIES[0]] }),
    })
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ facilities: [MOCK_FACILITIES[1]] }),
    })

    vi.stubGlobal('fetch', fetchMock)

    const { result, rerender } = renderHook(
      (cityId: number | undefined) => useFacilities(cityId),
      { initialProps: undefined }
    )

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    rerender(1)

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock).toHaveBeenLastCalledWith('/api/v1/facilities?city_id=1', {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
    })
  })

  it('returns empty array on non-ok response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
        json: () => Promise.resolve({}),
      })
    )

    const { result } = renderHook(() => useFacilities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBe('Request failed: 500')
  })

  it('returns empty array on network error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

    const { result } = renderHook(() => useFacilities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBe('Network error')
  })

  it('shows loading state while fetching', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ facilities: MOCK_FACILITIES }),
      })
    )

    const { result } = renderHook(() => useFacilities())

    expect(result.current.isLoading).toBe(true)
    expect(result.current.facilities).toEqual([])

    await waitFor(() => expect(result.current.isLoading).toBe(false))
  })

  it('returns empty array when no auth token is present', async () => {
    localStorage.clear()

    const { result } = renderHook(() => useFacilities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBe('Not authenticated')
  })

  it('returns empty array on malformed response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ unexpected: true }),
      })
    )

    const { result } = renderHook(() => useFacilities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBe('Invalid response format')
  })
})
