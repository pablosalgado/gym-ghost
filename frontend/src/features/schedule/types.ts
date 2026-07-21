/**
 * Schedule domain types for the mock schedule module.
 * Display names are translation keys derived from ids
 * (`schedule.facilities.<id>`, `schedule.classes.<id>`).
 */

export const FACILITIES = [
  // timeZone is reserved for future multi-timezone support;
  // all current facilities use America/Bogota.
  { id: 'chapinero', cityId: 1, timeZone: 'America/Bogota' },
  { id: 'zona-t', cityId: 1, timeZone: 'America/Bogota' },
  { id: 'poblado', cityId: 2, timeZone: 'America/Bogota' },
  { id: 'laureles', cityId: 2, timeZone: 'America/Bogota' },
] as const

export type FacilityId = (typeof FACILITIES)[number]['id']

export interface Facility {
  id: FacilityId
  cityId: number
  timeZone: string
}

export interface ApiCity {
  id: number
  city_name: string
}

export interface ApiFacility {
  id: number
  display_name: string
  city_id: number
}

export const CLASS_TYPES = [
  { id: 'spinning' },
  { id: 'yoga' },
  { id: 'crossfit' },
  { id: 'pilates' },
  { id: 'boxing' },
  { id: 'functional' },
] as const

export type ClassTypeId = (typeof CLASS_TYPES)[number]['id']

export interface ClassType {
  id: ClassTypeId
}

export interface Session {
  id: string
  facilityId: FacilityId
  classTypeId: ClassTypeId
  /** UTC ISO 8601 instant. */
  startsAt: string
  durationMinutes: number
}
