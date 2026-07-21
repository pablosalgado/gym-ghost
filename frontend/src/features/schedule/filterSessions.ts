import { type ClassTypeId, type Facility, type Session } from './types'

export interface ScheduleFilters {
  cityId?: number
  facilityId?: number
  classTypeId?: ClassTypeId
}

/** Filter sessions by optional city, facility, and class type constraints. */
export function filterSessions(
  sessions: readonly Session[],
  filters: ScheduleFilters,
  facilities: readonly Facility[]
): Session[] {
  return sessions.filter((session) => {
    if (filters.cityId) {
      const cityFacilityIds = new Set(
        facilities
          .filter((f) => String(f.cityId) === String(filters.cityId))
          .map((f) => String(f.id))
      )
      if (!cityFacilityIds.has(String(session.facilityId))) return false
    }

    if (filters.facilityId && String(session.facilityId) !== String(filters.facilityId)) {
      return false
    }

    if (filters.classTypeId && session.classTypeId !== filters.classTypeId) {
      return false
    }

    return true
  })
}
