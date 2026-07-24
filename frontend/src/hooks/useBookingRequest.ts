import { useCallback, useEffect, useRef, useState } from 'react'
import { AUTH_TOKEN_STORAGE_KEY } from './useAuth'
import {
  isBookingRequestResponse,
  isErrorResponse,
  type BookingRequest,
} from '../lib/api-types'

export interface UseBookingRequestResult {
  create: (scheduleEntryId: number) => Promise<void>
  isLoading: boolean
  error: string | null
  bookingRequest: BookingRequest | null
}

export function useBookingRequest(): UseBookingRequestResult {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [bookingRequest, setBookingRequest] = useState<BookingRequest | null>(null)
  const cancelledRef = useRef(false)

  useEffect(() => {
    return () => {
      cancelledRef.current = true
    }
  }, [])

  const create = useCallback(async (scheduleEntryId: number) => {
    const token = localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)
    if (!token) {
      setError('Not authenticated')
      return
    }

    cancelledRef.current = false
    setIsLoading(true)
    setError(null)
    setBookingRequest(null)

    try {
      const response = await fetch('/api/v1/booking_requests', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ schedule_entry_id: scheduleEntryId }),
      })

      if (cancelledRef.current) return

      const payload: unknown = await response.json()

      if (cancelledRef.current) return

      if (response.status === 409) {
        setError('Already requested')
        return
      }

      if (!response.ok) {
        if (isErrorResponse(payload) && payload.errors.length > 0) {
          setError(payload.errors[0].detail)
        } else {
          setError(`Request failed: ${response.status}`)
        }
        return
      }

      if (!isBookingRequestResponse(payload)) {
        setError('Invalid response format')
        return
      }

      setBookingRequest(payload.booking_request)
    } catch {
      if (cancelledRef.current) return
      setError('Network error')
    } finally {
      if (!cancelledRef.current) {
        setIsLoading(false)
      }
    }
  }, [])

  return { create, isLoading, error, bookingRequest }
}
