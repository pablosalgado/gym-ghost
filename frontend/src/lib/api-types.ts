// Manually maintained to match docs/openapi.yml (OpenAPI 3.0.3).
// Re-generate with openapi-typescript when it supports TypeScript 7+.

/** POST /api/v1/auth request body */
export interface LoginRequest {
  email: string
  password: string
}

/** POST /api/v1/auth — 200 response */
export interface LoginResponse {
  token: string
}

/** Shared error item in the errors array */
export interface ErrorItem {
  status: number
  title: string
  detail: string
}

/** Shared error response shape */
export interface ErrorResponse {
  errors: ErrorItem[]
}

/** GET /api/v1/cities — single city */
export interface City {
  id: number
  city_name: string
}

/** GET /api/v1/cities — 200 response */
export interface CitiesResponse {
  cities: City[]
}

/** GET /api/v1/facilities — single facility */
export interface Facility {
  id: number
  display_name: string
  city_id: number
}

/** GET /api/v1/facilities — 200 response */
export interface FacilitiesResponse {
  facilities: Facility[]
}

/** GET /api/v1/schedule — single schedule entry */
export interface ScheduleItem {
  id: number
  name: string
  facility_id: number
  city_id: number
  starts_at: string
  duration_minutes: number
}

/** GET /api/v1/schedule — 200 response */
export interface ScheduleResponse {
  schedule: ScheduleItem[]
}

/** Type guard: checks if a payload is a valid ErrorResponse */
export function isErrorResponse(payload: unknown): payload is ErrorResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'errors' in payload &&
    Array.isArray((payload as Record<string, unknown>).errors)
  )
}

/** Type guard: checks if a payload is a valid LoginResponse */
export function isLoginResponse(payload: unknown): payload is LoginResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'token' in payload &&
    typeof (payload as Record<string, unknown>).token === 'string'
  )
}

/** Type guard: checks if a payload is a valid CitiesResponse */
export function isCitiesResponse(payload: unknown): payload is CitiesResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'cities' in payload &&
    Array.isArray((payload as Record<string, unknown>).cities)
  )
}

/** Type guard: checks if a payload is a valid FacilitiesResponse */
export function isFacilitiesResponse(payload: unknown): payload is FacilitiesResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'facilities' in payload &&
    Array.isArray((payload as Record<string, unknown>).facilities)
  )
}

/** Type guard: checks if a payload is a valid ScheduleResponse */
export function isScheduleResponse(payload: unknown): payload is ScheduleResponse {
  if (typeof payload !== 'object' || payload === null) return false
  if (!('schedule' in payload)) return false
  const items = (payload as Record<string, unknown>).schedule
  if (!Array.isArray(items)) return false
  return items.every(
    (item) =>
      typeof item === 'object' &&
      item !== null &&
      'id' in item &&
      'name' in item &&
      'facility_id' in item &&
      'city_id' in item &&
      'starts_at' in item &&
      'duration_minutes' in item
  )
}
