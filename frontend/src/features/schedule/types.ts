export interface Session {
  id: string
  facilityId: number
  activityName: string
  activityId: number
  /** UTC ISO 8601 instant. */
  startsAt: string
}
