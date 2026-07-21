import { act, renderHook, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useCities } from './useCities'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

const AUTH_TOKEN = 'test-token-123'

const MOCK_CITIES = [
  { id: 1, city_name: 'Bogotá' },
  { id: 2, city_name: 'Medellín' },
]

describe('useCities', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('returns cities on successful fetch', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ cities: MOCK_CITIES }),
      })
    )

    const { result } = renderHook(() => useCities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.cities).toEqual(MOCK_CITIES)
    expect(result.current.error).toBeNull()
    expect(fetch).toHaveBeenCalledWith('/api/v1/cities', {
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

    const { result } = renderHook(() => useCities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.cities).toEqual([])
    expect(result.current.error).toBe('Request failed: 500')
  })

  it('returns empty array on network error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

    const { result } = renderHook(() => useCities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.cities).toEqual([])
    expect(result.current.error).toBe('Network error')
  })

  it('shows loading state while fetching', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ cities: MOCK_CITIES }),
      })
    )

    const { result } = renderHook(() => useCities())

    expect(result.current.isLoading).toBe(true)
    expect(result.current.cities).toEqual([])

    await waitFor(() => expect(result.current.isLoading).toBe(false))
  })

  it('returns empty array when no auth token is present', async () => {
    localStorage.clear()

    const { result } = renderHook(() => useCities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.cities).toEqual([])
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

    const { result } = renderHook(() => useCities())

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.cities).toEqual([])
    expect(result.current.error).toBe('Invalid response format')
  })
})
