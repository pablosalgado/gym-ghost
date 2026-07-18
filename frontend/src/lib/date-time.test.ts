import { describe, expect, it } from 'vitest'
import {
  DEFAULT_TIME_ZONE,
  addDays,
  formatDayLabel,
  formatTimeOfDay,
  todayInZone,
  toDateKey,
  wallTimeInZoneToUtc,
  windowFromToday,
} from './date-time'

const BOGOTA = 'America/Bogota'

describe('DEFAULT_TIME_ZONE', () => {
  it('is America/Bogota', () => {
    expect(DEFAULT_TIME_ZONE).toBe(BOGOTA)
  })
})

describe('todayInZone', () => {
  it('returns the previous day when UTC is past midnight but Bogotá is not', () => {
    // 2026-07-18T02:30:00Z is 2026-07-17 21:30 in Bogotá (UTC-5)
    expect(todayInZone(BOGOTA, new Date('2026-07-18T02:30:00Z'))).toEqual({
      year: 2026,
      month: 7,
      day: 17,
    })
  })

  it('returns the new day once Bogotá has passed midnight', () => {
    // 2026-07-18T06:00:00Z is 2026-07-18 01:00 in Bogotá
    expect(todayInZone(BOGOTA, new Date('2026-07-18T06:00:00Z'))).toEqual({
      year: 2026,
      month: 7,
      day: 18,
    })
  })

  it('defaults to the app time zone', () => {
    expect(todayInZone(undefined, new Date('2026-07-18T02:30:00Z'))).toEqual({
      year: 2026,
      month: 7,
      day: 17,
    })
  })

  it('throws RangeError for an invalid IANA zone', () => {
    expect(() => todayInZone('Mars/Olympus')).toThrow(RangeError)
  })
})

describe('addDays', () => {
  it('adds within a month', () => {
    expect(addDays({ year: 2026, month: 7, day: 17 }, 5)).toEqual({
      year: 2026,
      month: 7,
      day: 22,
    })
  })

  it('crosses a month boundary', () => {
    expect(addDays({ year: 2026, month: 7, day: 31 }, 1)).toEqual({
      year: 2026,
      month: 8,
      day: 1,
    })
  })

  it('crosses a year boundary', () => {
    expect(addDays({ year: 2026, month: 12, day: 31 }, 1)).toEqual({
      year: 2027,
      month: 1,
      day: 1,
    })
  })

  it('subtracts days with negative n', () => {
    expect(addDays({ year: 2026, month: 3, day: 1 }, -1)).toEqual({
      year: 2026,
      month: 2,
      day: 28,
    })
  })
})

describe('toDateKey', () => {
  it('zero-pads month and day', () => {
    expect(toDateKey({ year: 2026, month: 7, day: 5 })).toBe('2026-07-05')
  })
})

describe('windowFromToday', () => {
  it('returns 14 consecutive keys starting at today in Bogotá', () => {
    const keys = windowFromToday(14, BOGOTA, new Date('2026-07-18T02:30:00Z'))
    expect(keys).toHaveLength(14)
    expect(keys[0]).toBe('2026-07-17')
    expect(keys[13]).toBe('2026-07-30')
    for (let i = 1; i < keys.length; i += 1) {
      const [year, month, day] = keys[i - 1].split('-').map(Number)
      expect(keys[i]).toBe(toDateKey(addDays({ year, month, day }, 1)))
    }
  })
})

describe('formatTimeOfDay', () => {
  const INSTANT = '2026-07-20T12:00:00.000Z' // 07:00 in Bogotá

  it('formats the instant in the zone for es-CO', () => {
    const expected = new Intl.DateTimeFormat('es-CO', {
      timeZone: BOGOTA,
      hour: 'numeric',
      minute: '2-digit',
    }).format(new Date(INSTANT))
    expect(formatTimeOfDay(INSTANT, 'es-CO')).toBe(expected)
  })

  it('formats the instant in the zone for en-US', () => {
    const expected = new Intl.DateTimeFormat('en-US', {
      timeZone: BOGOTA,
      hour: 'numeric',
      minute: '2-digit',
    }).format(new Date(INSTANT))
    expect(formatTimeOfDay(INSTANT, 'en-US')).toBe(expected)
  })

  it('renders differently between es-CO and en-US', () => {
    expect(formatTimeOfDay(INSTANT, 'es-CO')).not.toBe(
      formatTimeOfDay(INSTANT, 'en-US')
    )
  })

  it('throws for a malformed ISO instant', () => {
    expect(() => formatTimeOfDay('not-a-date', 'es-CO')).toThrow()
  })
})

describe('formatDayLabel', () => {
  it('returns the weekday and day number for the calendar date', () => {
    const { weekday, day } = formatDayLabel('2026-07-17', 'es-CO')
    const expectedWeekday = new Intl.DateTimeFormat('es-CO', {
      timeZone: 'UTC',
      weekday: 'short',
    }).format(new Date(Date.UTC(2026, 6, 17, 12)))
    expect(weekday).toBe(expectedWeekday)
    expect(day).toBe(17)
  })
})

describe('wallTimeInZoneToUtc', () => {
  it('converts Bogotá wall time to the correct UTC instant', () => {
    expect(wallTimeInZoneToUtc('2026-07-20', 7, 0, BOGOTA).toISOString()).toBe(
      '2026-07-20T12:00:00.000Z'
    )
  })

  it('converts a pre-midnight wall time that stays on the same UTC day', () => {
    // 23:30 Bogotá is 04:30 UTC the next day
    expect(wallTimeInZoneToUtc('2026-07-20', 23, 30, BOGOTA).toISOString()).toBe(
      '2026-07-21T04:30:00.000Z'
    )
  })

  it('throws RangeError for an invalid IANA zone', () => {
    expect(() => wallTimeInZoneToUtc('2026-07-20', 7, 0, 'Mars/Olympus')).toThrow(
      RangeError
    )
  })
})
