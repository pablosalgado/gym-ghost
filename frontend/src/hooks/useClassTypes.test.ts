import { renderHook, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useClassTypes } from './useClassTypes'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

const AUTH_TOKEN = 'test-token-123'

const MOCK_CLASS_TYPES = [
  { id: 1, name: 'Yoga' },
  { id: 2, name: 'Spinning' },
]

describe('useClassTypes', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('fetches all class types when no facilityId is provided', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ class_types: MOCK_CLASS_TYPES }),
      })
    )

    const { result } = renderHook(() => useClassTypes())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.classTypes).toEqual(MOCK_CLASS_TYPES)
    expect(result.current.error).toBeNull()
    expect(fetch).toHaveBeenCalledWith('/api/v1/class_types', {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
    })
  })

  it('filters class types by facilityId when provided', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ class_types: [MOCK_CLASS_TYPES[0]] }),
      })
    )

    const { result } = renderHook(() => useClassTypes(1))

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.classTypes).toEqual([MOCK_CLASS_TYPES[0]])
    expect(fetch).toHaveBeenCalledWith('/api/v1/class_types?facility_id=1', {
      headers: { Authorization: `Bearer ${AUTH_TOKEN}` },
    })
  })

  it('re-fetches when facilityId changes', async () => {
    const fetchMock = vi.fn()

    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ class_types: [MOCK_CLASS_TYPES[0]] }),
    })
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ class_types: [MOCK_CLASS_TYPES[1]] }),
    })

    vi.stubGlobal('fetch', fetchMock)

    const { result, rerender } = renderHook(
      (facilityId: number | undefined) => useClassTypes(facilityId),
      { initialProps: undefined }
    )

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    rerender(1)

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock).toHaveBeenLastCalledWith('/api/v1/class_types?facility_id=1', {
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

    const { result } = renderHook(() => useClassTypes())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Request failed: 500')
  })

  it('returns empty array on network error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

    const { result } = renderHook(() => useClassTypes())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Network error')
  })

  it('shows loading state while fetching', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ class_types: MOCK_CLASS_TYPES }),
      })
    )

    const { result } = renderHook(() => useClassTypes())

    expect(result.current.isLoading).toBe(true)
    expect(result.current.classTypes).toEqual([])

    await waitFor(() => expect(result.current.isLoading).toBe(false))
  })

  it('returns empty array when no auth token is present', async () => {
    localStorage.clear()

    const { result } = renderHook(() => useClassTypes())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.classTypes).toEqual([])
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

    const { result } = renderHook(() => useClassTypes())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.classTypes).toEqual([])
    expect(result.current.error).toBe('Invalid response format')
  })
})
