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

/** GET /api/v1/schedule — single class type */
export interface ClassType {
  id: number
  name: string
}

/** POST /api/v1/booking_requests — booking request status per schedule entry */
export interface BookingRequest {
  id: number
  schedule_entry_id: number
  status: "pending" | "booked" | "failed"
  booking_window_opens_at: string
}

/** GET /api/v1/schedule — single schedule entry */
export interface ScheduleItem {
  id: number
  activity_name: string
  activity_id: number
  facility_id: number
  starts_at: string
  booking_request?: BookingRequest | null
}

/** GET /api/v1/schedule — 200 response */
export interface ScheduleResponse {
  schedule: ScheduleItem[]
  class_types: ClassType[]
}

/** GET /api/v1/gym_members — single gym member */
export interface GymMember {
  id: number
  email: string
}

/** POST /api/v1/gym_members — request body */
export interface CreateGymMemberRequest {
  email: string
  password: string
}

/** POST /api/v1/gym_members — 201 response */
export interface CreateGymMemberResponse {
  gym_member: GymMember
}

/** GET /api/v1/gym_members — 200 response */
export interface GymMembersResponse {
  gym_members: GymMember[]
}

/** PATCH /api/v1/gym_members/:id / POST /api/v1/gym_members — single gym member response */
export interface GymMemberResponse {
  gym_member: GymMember
}

/** PATCH /api/v1/gym_members/:id — request body (password only for inline update) */
export interface UpdateGymMemberRequest {
  password: string
}

/** POST /api/v1/booking_requests — 200 response */
export interface CreateBookingRequestResponse {
  booking_request: BookingRequest
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
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'schedule' in payload &&
    Array.isArray((payload as Record<string, unknown>).schedule) &&
    'class_types' in payload &&
    Array.isArray((payload as Record<string, unknown>).class_types)
  )
}

/** Type guard: checks if a payload is a valid CreateGymMemberResponse */
export function isCreateGymMemberResponse(payload: unknown): payload is CreateGymMemberResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'gym_member' in payload &&
    typeof (payload as Record<string, unknown>).gym_member === 'object' &&
    (payload as Record<string, unknown>).gym_member !== null
  )
}

/** Type guard: checks if a payload is a valid GymMembersResponse */
export function isGymMembersResponse(payload: unknown): payload is GymMembersResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'gym_members' in payload &&
    Array.isArray((payload as Record<string, unknown>).gym_members)
  )
}

/** Type guard: checks if a payload is a valid GymMemberResponse */
export function isGymMemberResponse(payload: unknown): payload is GymMemberResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'gym_member' in payload &&
    typeof (payload as Record<string, unknown>).gym_member === 'object' &&
    (payload as Record<string, unknown>).gym_member !== null
  )
}
/** Type guard: checks if a payload is a valid CreateBookingRequestResponse */
export function isBookingRequestResponse(payload: unknown): payload is CreateBookingRequestResponse {
  return (
    typeof payload === 'object' &&
    payload !== null &&
    'booking_request' in payload &&
    typeof (payload as Record<string, unknown>).booking_request === 'object' &&
    (payload as Record<string, unknown>).booking_request !== null
  )
}
