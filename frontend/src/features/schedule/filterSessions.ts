import type { Session } from './types'

export interface ScheduleFilters {
  cityId?: number
  facilityId?: number
  classTypeId?: string
}

/** Filter sessions by optional city, facility, and class type constraints. */
export function filterSessions(
  sessions: readonly Session[],
  filters: ScheduleFilters,
): Session[] {
  return sessions.filter((session) => {
    if (filters.facilityId !== undefined && session.facilityId !== filters.facilityId) {
      return false
    }

    if (filters.classTypeId !== undefined && session.activityName !== filters.classTypeId) {
      return false
    }

    return true
  })
}
