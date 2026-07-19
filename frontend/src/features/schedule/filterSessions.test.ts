import { describe, expect, it } from 'vitest'
import { filterSessions } from './filterSessions'
import { FACILITIES, type Session } from './types'

function makeSession(overrides: Partial<Session> = {}): Session {
  return {
    id: 'test-1',
    facilityId: 'chapinero',
    classTypeId: 'yoga',
    startsAt: '2026-07-20T12:00:00.000Z',
    durationMinutes: 60,
    ...overrides,
  }
}

const TEST_SESSIONS: readonly Session[] = [
  makeSession({ id: 's1', facilityId: 'chapinero', classTypeId: 'yoga' }),
  makeSession({ id: 's2', facilityId: 'zona-t', classTypeId: 'spinning' }),
  makeSession({ id: 's3', facilityId: 'poblado', classTypeId: 'yoga' }),
  makeSession({ id: 's4', facilityId: 'laureles', classTypeId: 'boxing' }),
]

describe('filterSessions', () => {
  it('returns all sessions when no filters are applied', () => {
    expect(filterSessions(TEST_SESSIONS, {}, FACILITIES)).toHaveLength(4)
  })

  it('filters by city through facility mapping', () => {
    const result = filterSessions(TEST_SESSIONS, { cityId: 'bogota' }, FACILITIES)
    expect(result.map((s) => s.id)).toEqual(['s1', 's2'])
  })

  it('filters by facility directly', () => {
    const result = filterSessions(TEST_SESSIONS, { facilityId: 'poblado' }, FACILITIES)
    expect(result.map((s) => s.id)).toEqual(['s3'])
  })

  it('filters by class type', () => {
    const result = filterSessions(TEST_SESSIONS, { classTypeId: 'yoga' }, FACILITIES)
    expect(result.map((s) => s.id)).toEqual(['s1', 's3'])
  })

  it('composes city and class type with AND logic', () => {
    const result = filterSessions(
      TEST_SESSIONS,
      { cityId: 'bogota', classTypeId: 'yoga' },
      FACILITIES
    )
    expect(result.map((s) => s.id)).toEqual(['s1'])
  })

  it('returns empty array when no sessions match', () => {
    const result = filterSessions(
      TEST_SESSIONS,
      { cityId: 'medellin', classTypeId: 'spinning' },
      FACILITIES
    )
    expect(result).toHaveLength(0)
  })
})
