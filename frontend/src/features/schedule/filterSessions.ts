import { type CityId, type ClassTypeId, type FacilityId, type Facility, type Session } from './types'

export interface ScheduleFilters {
  cityId?: CityId
  facilityId?: FacilityId
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
          .filter((facility) => facility.cityId === filters.cityId)
          .map((facility) => facility.id)
      )
      if (!cityFacilityIds.has(session.facilityId)) return false
    }

    if (filters.facilityId && session.facilityId !== filters.facilityId) {
      return false
    }

    if (filters.classTypeId && session.classTypeId !== filters.classTypeId) {
      return false
    }

    return true
  })
}
