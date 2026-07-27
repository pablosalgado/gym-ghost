import { act, renderHook, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useBookingRequest } from './useBookingRequest'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'

const AUTH_TOKEN = 'test-token-123'

const MOCK_BOOKING_REQUEST = {
  id: 1,
  schedule_entry_id: 42,
  status: 'pending' as const,
  booking_window_opens_at: '2026-07-24T10:00:00.000Z',
}

const MOCK_SUCCESS_RESPONSE = { booking_request: MOCK_BOOKING_REQUEST }

describe('useBookingRequest', () => {
  beforeEach(() => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, AUTH_TOKEN)
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('initialises with no booking request', () => {
    const { result } = renderHook(() => useBookingRequest())

    expect(result.current.bookingRequest).toBeNull()
    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
  })

  it('posts to booking_requests endpoint and stores the returned booking request', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        status: 201,
        json: () => Promise.resolve(MOCK_SUCCESS_RESPONSE),
      })
    )

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.bookingRequest).toEqual(MOCK_BOOKING_REQUEST)
    expect(result.current.error).toBeNull()
    expect(fetch).toHaveBeenCalledWith('/api/v1/booking_requests', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${AUTH_TOKEN}`,
      },
      body: JSON.stringify({ schedule_entry_id: 42 }),
    })
  })

  it('sets error "Already requested" on 409 conflict', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 409,
        json: () => Promise.resolve({}),
      })
    )

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.error).toBe('Already requested')
    expect(result.current.bookingRequest).toBeNull()
  })

  it('sets error from server detail on other non-ok responses', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        json: () => Promise.resolve({
          errors: [{ status: 422, title: 'Validation Failed', detail: 'Schedule entry is in the past.' }],
        }),
      })
    )

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.error).toBe('Schedule entry is in the past.')
    expect(result.current.bookingRequest).toBeNull()
  })

  it('sets error with status fallback on non-ok response without errors array', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
        json: () => Promise.resolve({}),
      })
    )

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.error).toBe('Request failed: 500')
  })

  it('sets error "Network error" when fetch rejects', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.error).toBe('Network error')
    expect(result.current.bookingRequest).toBeNull()
  })

  it('sets error "Not authenticated" when no token is present', async () => {
    localStorage.clear()

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.error).toBe('Not authenticated')
    expect(result.current.isLoading).toBe(false)
  })

  it('shows loading state while request is in flight', async () => {
    let resolveFetch: (value: unknown) => void
    const fetchPromise = new Promise<unknown>((resolve) => {
      resolveFetch = resolve
    })
    vi.stubGlobal('fetch', vi.fn().mockReturnValue(fetchPromise))

    const { result } = renderHook(() => useBookingRequest())

    // Fire create without awaiting — the synchronous setIsLoading(true) runs
    // inside the synchronous portion of create, then create awaits fetchPromise.
    result.current.create(42)

    // Flush React batched state updates so isLoading is committed
    await act(() => Promise.resolve())

    expect(result.current.isLoading).toBe(true)
    expect(result.current.bookingRequest).toBeNull()

    // Resolve the fetch so the hook can finish
    await act(async () => {
      resolveFetch!({
        ok: true,
        status: 201,
        json: () => Promise.resolve(MOCK_SUCCESS_RESPONSE),
      })
    })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
  })

  it('resets previous state when create is called again', async () => {
    const fetchMock = vi.fn()

    fetchMock.mockResolvedValueOnce({
      ok: true,
      status: 201,
      json: () => Promise.resolve(MOCK_SUCCESS_RESPONSE),
    })

    const secondBookingRequest = {
      id: 2,
      schedule_entry_id: 99,
      status: 'pending' as const,
      booking_window_opens_at: '2026-07-25T08:00:00.000Z',
    }

    fetchMock.mockResolvedValueOnce({
      ok: true,
      status: 201,
      json: () => Promise.resolve({ booking_request: secondBookingRequest }),
    })

    vi.stubGlobal('fetch', fetchMock)

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.bookingRequest).toEqual(MOCK_BOOKING_REQUEST)

    await act(async () => {
      await result.current.create(99)
    })

    expect(result.current.bookingRequest).toEqual(secondBookingRequest)
    expect(fetchMock).toHaveBeenCalledTimes(2)
    expect(fetchMock).toHaveBeenLastCalledWith('/api/v1/booking_requests', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${AUTH_TOKEN}`,
      },
      body: JSON.stringify({ schedule_entry_id: 99 }),
    })
  })

  it('sets error "Invalid response format" on malformed success response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        status: 201,
        json: () => Promise.resolve({ unexpected: true }),
      })
    )

    const { result } = renderHook(() => useBookingRequest())

    await act(async () => {
      await result.current.create(42)
    })

    expect(result.current.error).toBe('Invalid response format')
    expect(result.current.bookingRequest).toBeNull()
  })

  it('ignores response when component unmounts during fetch', async () => {
    let resolveJson: (value: unknown) => void
    const jsonPromise = new Promise<unknown>((resolve) => {
      resolveJson = resolve
    })

    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        status: 201,
        json: () => jsonPromise,
      })
    )

    const { result, unmount } = renderHook(() => useBookingRequest())

    let createPromise: Promise<void> = Promise.resolve()
    await act(async () => {
      createPromise = result.current.create(42)
    })

    unmount()

    // Resolve the pending json after unmount
    resolveJson!(MOCK_SUCCESS_RESPONSE)

    await createPromise

    expect(result.current.bookingRequest).toBeNull()
    expect(result.current.error).toBeNull()
  })

  describe('cancel', () => {
    it('deletes the booking request and returns true on success', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          ok: true,
          status: 204,
        })
      )

      const { result } = renderHook(() => useBookingRequest())

      // First create a booking request so one is tracked
      vi.stubGlobal(
        'fetch',
        vi.fn()
          .mockResolvedValueOnce({
            ok: true,
            status: 201,
            json: () => Promise.resolve(MOCK_SUCCESS_RESPONSE),
          })
          .mockResolvedValueOnce({
            ok: true,
            status: 204,
          })
      )

      await act(async () => {
        await result.current.create(42)
      })

      expect(result.current.bookingRequest).not.toBeNull()

      const success = await act(() => result.current.cancel(1))

      expect(success).toBe(true)
      expect(result.current.bookingRequest).toBeNull()
      expect(result.current.error).toBeNull()
      expect(result.current.isLoading).toBe(false)
      expect(fetch).toHaveBeenLastCalledWith('/api/v1/booking_requests/1', {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${AUTH_TOKEN}`,
        },
      })
    })

    it('returns false and sets error on 404 not found', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          ok: false,
          status: 404,
        })
      )

      const { result } = renderHook(() => useBookingRequest())

      const success = await act(() => result.current.cancel(999))

      expect(success).toBe(false)
      expect(result.current.error).toBe('Booking request not found')
      expect(result.current.isLoading).toBe(false)
    })

    it('returns false and sets error on other non-ok responses', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          ok: false,
          status: 500,
          json: () => Promise.resolve({
            errors: [{ status: 500, title: 'Internal Server Error', detail: 'Something went wrong' }],
          }),
        })
      )

      const { result } = renderHook(() => useBookingRequest())

      const success = await act(() => result.current.cancel(1))

      expect(success).toBe(false)
      expect(result.current.error).toBe('Something went wrong')
      expect(result.current.isLoading).toBe(false)
    })

    it('returns false on network error', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Network down')))

      const { result } = renderHook(() => useBookingRequest())

      const success = await act(() => result.current.cancel(1))

      expect(success).toBe(false)
      expect(result.current.error).toBe('Network error')
      expect(result.current.isLoading).toBe(false)
    })

    it('returns false when no auth token is present', async () => {
      localStorage.clear()

      const { result } = renderHook(() => useBookingRequest())

      const success = await act(() => result.current.cancel(1))

      expect(success).toBe(false)
      expect(result.current.error).toBe('Not authenticated')
      expect(result.current.isLoading).toBe(false)
    })

    it('returns false when component unmounts during cancel', async () => {
      let resolveFetch: (value: unknown) => void
      const fetchPromise = new Promise<unknown>((resolve) => {
        resolveFetch = resolve
      })
      vi.stubGlobal('fetch', vi.fn().mockReturnValue(fetchPromise))

      const { result, unmount } = renderHook(() => useBookingRequest())

      let cancelPromise: Promise<boolean> = Promise.resolve(false)
      await act(async () => {
        cancelPromise = result.current.cancel(1)
      })

      unmount()

      resolveFetch!({ ok: true, status: 204 })

      const success = await cancelPromise

      expect(success).toBe(false)
      expect(result.current.error).toBeNull()
    })
  })
})
