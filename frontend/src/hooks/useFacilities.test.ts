import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useFacilities } from './useFacilities'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

const AUTH_TOKEN = 'test-token-123'

const MOCK_FACILITIES = [
  { id: 1, display_name: 'Chapinero', city_id: 1 },
  { id: 2, display_name: 'Usaquén', city_id: 1 },
]

const OTHER_CITY_FACILITIES = [
  { id: 3, display_name: 'El Poblado', city_id: 2 },
]

interface MockResponse {
  ok: boolean
  status?: number
  json: () => Promise<unknown>
}

function deferred<T>() {
  let resolvePromise: (value: T | PromiseLike<T>) => void = () => {
    throw new Error('Promise resolver not initialized')
  }
  const promise = new Promise<T>((resolve) => {
    resolvePromise = resolve
  })

  return { promise, resolve: resolvePromise }
}

describe('useFacilities', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('does not fetch facilities when no cityId is provided', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ facilities: MOCK_FACILITIES }),
      })
    )

    const { result } = renderHook(() => useFacilities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBeNull()
    expect(fetch).not.toHaveBeenCalled()
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
    expect(fetch).toHaveBeenCalledWith(
      '/api/v1/facilities?city_id=1',
      expect.objectContaining({
        headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
        signal: expect.any(AbortSignal),
      }),
    )
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
      { initialProps: 1 }
    )

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    rerender(2)

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock).toHaveBeenLastCalledWith(
      '/api/v1/facilities?city_id=2',
      expect.objectContaining({
        headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
        signal: expect.any(AbortSignal),
      }),
    )
  })

  it('ignores responses from a previous city', async () => {
    const firstResponse = deferred<MockResponse>()
    const secondResponse = deferred<MockResponse>()
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => firstResponse.promise)
      .mockImplementationOnce(() => secondResponse.promise)
    vi.stubGlobal('fetch', fetchMock)

    const { result, rerender } = renderHook(
      (cityId: number | undefined) => useFacilities(cityId),
      { initialProps: 1 },
    )

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1))
    const firstSignal = fetchMock.mock.calls[0]?.[1]?.signal

    rerender(2)

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(firstSignal).toBeInstanceOf(AbortSignal)
    expect(firstSignal.aborted).toBe(true)

    secondResponse.resolve({
      ok: true,
      json: () => Promise.resolve({ facilities: OTHER_CITY_FACILITIES }),
    })

    await waitFor(() => {
      expect(result.current.facilities).toEqual(OTHER_CITY_FACILITIES)
      expect(result.current.isLoading).toBe(false)
    })

    firstResponse.resolve({
      ok: false,
      status: 500,
      json: () => Promise.resolve({}),
    })

    await Promise.resolve()
    expect(result.current.facilities).toEqual(OTHER_CITY_FACILITIES)
    expect(result.current.error).toBeNull()
  })

  it('aborts an in-flight request on unmount', async () => {
    const response = deferred<MockResponse>()
    const fetchMock = vi.fn().mockImplementation(() => response.promise)
    vi.stubGlobal('fetch', fetchMock)

    const { unmount } = renderHook(() => useFacilities(1))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1))
    const signal = fetchMock.mock.calls[0]?.[1]?.signal

    unmount()

    expect(signal).toBeInstanceOf(AbortSignal)
    expect(signal.aborted).toBe(true)
  })

  it('reports loading immediately when cityId changes from undefined to a value', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ facilities: [MOCK_FACILITIES[0]] }),
      })
    )

    const { result, rerender } = renderHook(
      (currentCityId: number | undefined) => useFacilities(currentCityId),
      { initialProps: undefined }
    )

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    rerender(1)

    expect(result.current.isLoading).toBe(true)

    await waitFor(() => expect(result.current.isLoading).toBe(false))
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

    const { result } = renderHook(() => useFacilities(1))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBe('Request failed: 500')
  })

  it('returns empty array on network error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

    const { result } = renderHook(() => useFacilities(1))

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

    const { result } = renderHook(() => useFacilities(1))

    expect(result.current.isLoading).toBe(true)
    expect(result.current.facilities).toEqual([])

    await waitFor(() => expect(result.current.isLoading).toBe(false))
  })

  it('returns empty array when no auth token is present', async () => {
    localStorage.clear()

    const { result } = renderHook(() => useFacilities(1))

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

    const { result } = renderHook(() => useFacilities(1))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.facilities).toEqual([])
    expect(result.current.error).toBe('Invalid response format')
  })
})
