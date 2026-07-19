import { describe, expect, it } from 'vitest'
import {
  getCities,
  getClassTypes,
  getFacilities,
  getSessionsForDate,
} from './mockSchedule'
import { FACILITIES } from './types'

const ALLOWED_HOURS = new Set([6, 7, 8, 9, 12, 17, 18, 19])

describe('getSessionsForDate', () => {
  it('is deterministic: two calls return identical data', () => {
    expect(getSessionsForDate('2026-07-17')).toEqual(
      getSessionsForDate('2026-07-17')
    )
  })

  it('produces different sessions for different dates', () => {
    expect(getSessionsForDate('2026-07-17')).not.toEqual(
      getSessionsForDate('2026-07-18')
    )
  })

  it('generates 3-6 sessions per facility with stable ids', () => {
    const sessions = getSessionsForDate('2026-07-20')
    for (const facility of FACILITIES) {
      const own = sessions.filter(
        (session) => session.facilityId === facility.id
      )
      expect(own.length).toBeGreaterThanOrEqual(3)
      expect(own.length).toBeLessThanOrEqual(6)
      own.forEach((session, index) => {
        expect(session.id).toBe(`${facility.id}-2026-07-20-${index}`)
      })
    }
  })

  it('places every session inside its Bogotá day at an allowed hour', () => {
    const sessions = getSessionsForDate('2026-07-20')
    const bogotaDay = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'America/Bogota',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    })
    const bogotaHour = new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/Bogota',
      hour: 'numeric',
      hour12: false,
    })

    for (const session of sessions) {
      const instant = new Date(session.startsAt)
      expect(Number.isNaN(instant.getTime())).toBe(false)
      expect(bogotaDay.format(instant)).toBe('2026-07-20')
      expect(ALLOWED_HOURS.has(Number(bogotaHour.format(instant)))).toBe(true)
      expect(session.durationMinutes).toBe(60)
    }
  })

  it('serializes a 06:00 Bogotá start as 11:00 UTC', () => {
    const sessions = getSessionsForDate('2026-07-20')
    const sixAm = sessions.find(
      (session) => session.startsAt === '2026-07-20T11:00:00.000Z'
    )
    // At least one facility starts at 06:00 that day, and any 06:00 start
    // is exactly 11:00 UTC — never a hand-rolled offset.
    const bogotaHour = new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/Bogota',
      hour: 'numeric',
      hour12: false,
    })
    expect(sixAm).toBeDefined()
    expect(bogotaHour.format(new Date(sixAm!.startsAt))).toBe('06')
  })
})

describe('catalogs', () => {
  it('returns two cities', () => {
    expect(getCities().map((city) => city.id)).toEqual(['bogota', 'medellin'])
  })

  it('cascades facilities by city', () => {
    expect(getFacilities('bogota').map((facility) => facility.id)).toEqual([
      'chapinero',
      'zona-t',
    ])
    expect(getFacilities('medellin').map((facility) => facility.id)).toEqual([
      'poblado',
      'laureles',
    ])
    expect(getFacilities()).toHaveLength(4)
  })

  it('returns six class types', () => {
    expect(getClassTypes()).toHaveLength(6)
  })
})
