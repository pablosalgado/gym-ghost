import { describe, expect, it } from 'vitest'
import { filterSessions } from './filterSessions'
import type { Session } from './types'

function makeSession(overrides: Partial<Session> = {}): Session {
  return {
    id: 'test-1',
    facilityId: 1,
    activityName: 'yoga',
    activityId: 1,
    startsAt: '2026-07-20T12:00:00.000Z',
    ...overrides,
  }
}

const TEST_SESSIONS: readonly Session[] = [
  makeSession({ id: 's1', facilityId: 1, activityName: 'yoga', activityId: 1 }),
  makeSession({ id: 's2', facilityId: 2, activityName: 'spinning', activityId: 2 }),
  makeSession({ id: 's3', facilityId: 3, activityName: 'yoga', activityId: 1 }),
  makeSession({ id: 's4', facilityId: 4, activityName: 'boxing', activityId: 4 }),
]

describe('filterSessions', () => {
  it('returns all sessions when no filters are applied', () => {
    expect(filterSessions(TEST_SESSIONS, {})).toHaveLength(4)
  })

  it('filters by facility directly', () => {
    const result = filterSessions(TEST_SESSIONS, { facilityId: 3 })
    expect(result.map((s) => s.id)).toEqual(['s3'])
  })

  it('filters by class type', () => {
    const result = filterSessions(TEST_SESSIONS, { activityId: 1 })
    expect(result.map((s) => s.id)).toEqual(['s1', 's3'])
  })

  it('composes facility and class type with AND logic', () => {
    const result = filterSessions(
      TEST_SESSIONS,
      { facilityId: 1, activityId: 1 },
    )
    expect(result.map((s) => s.id)).toEqual(['s1'])
  })

  it('returns empty array when no sessions match', () => {
    const result = filterSessions(
      TEST_SESSIONS,
      { facilityId: 99, activityId: 2 },
    )
    expect(result).toHaveLength(0)
  })
})
