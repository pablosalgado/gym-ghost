/**
 * Date and time helpers for the gym-ghost frontend.
 *
 * Rules (see .github/instructions/date-time.instructions.md):
 * - Instants are UTC ISO 8601 strings; this module only derives zone-local
 *   calendar facts and formats them.
 * - "Today", windows, and calendar arithmetic are computed inside an explicit
 *   IANA zone — never via host-local Date getters.
 * - Offsets are derived from Intl at the target instant — never hardcoded.
 */

export const DEFAULT_TIME_ZONE = 'America/Bogota'

export interface DateParts {
  year: number
  month: number
  day: number
}

interface ZonedDateTimeParts extends DateParts {
  hour: number
  minute: number
}

function readPart(parts: Intl.DateTimeFormatPart[], type: string, timeZone: string): number {
  const part = parts.find((candidate) => candidate.type === type)
  if (!part) {
    throw new RangeError(`Intl did not return a ${type} part for zone ${timeZone}`)
  }
  return Number(part.value)
}

function zonedDateParts(timeZone: string, instant: Date): DateParts {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(instant)
  return {
    year: readPart(parts, 'year', timeZone),
    month: readPart(parts, 'month', timeZone),
    day: readPart(parts, 'day', timeZone),
  }
}

function zonedDateTimeParts(timeZone: string, instant: Date): ZonedDateTimeParts {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant)
  return {
    year: readPart(parts, 'year', timeZone),
    month: readPart(parts, 'month', timeZone),
    day: readPart(parts, 'day', timeZone),
    hour: readPart(parts, 'hour', timeZone),
    minute: readPart(parts, 'minute', timeZone),
  }
}

/** The calendar date of `now` inside `timeZone`. */
export function todayInZone(
  timeZone: string = DEFAULT_TIME_ZONE,
  now: Date = new Date()
): DateParts {
  return zonedDateParts(timeZone, now)
}

/** Calendar day arithmetic on date triples — DST-agnostic, never 86_400_000 ms. */
export function addDays(parts: DateParts, n: number): DateParts {
  const shifted = new Date(Date.UTC(parts.year, parts.month - 1, parts.day + n))
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
  }
}

/** `yyyy-mm-dd` key for a date triple (matches schedule data keys). */
export function toDateKey(parts: DateParts): string {
  const month = String(parts.month).padStart(2, '0')
  const day = String(parts.day).padStart(2, '0')
  return `${parts.year}-${month}-${day}`
}

/** `dayCount` consecutive date keys starting at today in `timeZone`. */
export function windowFromToday(
  dayCount: number,
  timeZone: string = DEFAULT_TIME_ZONE,
  now: Date = new Date()
): string[] {
  const start = todayInZone(timeZone, now)
  return Array.from({ length: dayCount }, (_, index) =>
    toDateKey(addDays(start, index))
  )
}

/** Localized wall-clock time of a UTC instant inside `timeZone`. */
export function formatTimeOfDay(
  isoUtc: string,
  locale: string,
  timeZone: string = DEFAULT_TIME_ZONE
): string {
  const instant = new Date(isoUtc)
  if (Number.isNaN(instant.getTime())) {
    throw new RangeError(`Cannot parse ISO 8601 instant: ${isoUtc}`)
  }
  return new Intl.DateTimeFormat(locale, {
    timeZone,
    hour: 'numeric',
    minute: '2-digit',
  }).format(instant)
}

/**
 * Short weekday label and day number for a `yyyy-mm-dd` key. The weekday is a
 * property of the calendar date, so it is computed in UTC.
 */
export function formatDayLabel(
  dateKey: string,
  locale: string,
  timeZone: string = DEFAULT_TIME_ZONE
): { weekday: string; day: number } {
  void timeZone // weekday is zone-independent; the parameter keeps the API uniform
  const [year, month, day] = dateKey.split('-').map(Number)
  const weekday = new Intl.DateTimeFormat(locale, {
    timeZone: 'UTC',
    weekday: 'short',
  }).format(new Date(Date.UTC(year, month - 1, day, 12)))
  return { weekday, day }
}

/**
 * The UTC instant of a wall-clock time in `timeZone` on `dateKey`.
 * Two-pass derivation: interpret the wall time as UTC, read the zone's wall
 * time at that instant, and shift by the difference. Exact for fixed-offset
 * zones like America/Bogota (no DST).
 */
export function wallTimeInZoneToUtc(
  dateKey: string,
  hour: number,
  minute: number,
  timeZone: string = DEFAULT_TIME_ZONE
): Date {
  const [year, month, day] = dateKey.split('-').map(Number)
  const wallAsUtc = Date.UTC(year, month - 1, day, hour, minute)
  const zoned = zonedDateTimeParts(timeZone, new Date(wallAsUtc))
  const zonedAsUtc = Date.UTC(
    zoned.year,
    zoned.month - 1,
    zoned.day,
    zoned.hour,
    zoned.minute
  )
  const offsetMs = zonedAsUtc - wallAsUtc
  return new Date(wallAsUtc - offsetMs)
}
