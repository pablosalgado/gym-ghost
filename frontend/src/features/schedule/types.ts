export interface Session {
  id: string
  facilityId: number
  classTypeId: string
  /** UTC ISO 8601 instant. */
  startsAt: string
  durationMinutes: number
}
