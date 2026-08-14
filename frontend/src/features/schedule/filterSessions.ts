import type { Session } from './types'

export interface ScheduleFilters {
  activityId?: number
}

/** Filter the loaded schedule by an optional class type selection. */
export function filterSessions(
  sessions: readonly Session[],
  filters: ScheduleFilters,
): Session[] {
  if (filters.activityId === undefined) {
    return [...sessions]
  }

  return sessions.filter((session) => session.activityId === filters.activityId)
}
