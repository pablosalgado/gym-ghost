import type { BookingRequest } from '../../lib/api-types'

export interface Session {
  id: string
  facilityId: number
  activityName: string
  activityId: number
  /** UTC ISO 8601 instant. */
  startsAt: string
  /** Booking request status from the schedule response, if any. */
  bookingRequest?: BookingRequest | null
}
