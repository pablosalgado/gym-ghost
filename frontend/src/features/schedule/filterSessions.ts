import type { Session } from './types'

export interface ScheduleFilters {
  cityId?: number
  facilityId?: number
  activityId?: number
}

/** Filter sessions by optional city, facility, and activity constraints. */
export function filterSessions(
  sessions: readonly Session[],
  filters: ScheduleFilters,
): Session[] {
  return sessions.filter((session) => {
    if (filters.facilityId !== undefined && session.facilityId !== filters.facilityId) {
      return false
    }

    if (filters.activityId !== undefined && session.activityId !== filters.activityId) {
      return false
    }

    return true
  })
}
