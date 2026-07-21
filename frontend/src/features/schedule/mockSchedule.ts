import { wallTimeInZoneToUtc } from '../../lib/date-time'
import {
  CLASS_TYPES,
  FACILITIES,
  type ClassType,
  type Session,
} from './types'

/**
 * Deterministic mock schedule data. Sessions are a pure function of
 * (dateKey, facilityId): same inputs, same outputs, forever. No Math.random,
 * no Date.now, no network. When a real API arrives, only this module changes.
 */

const START_HOURS = [6, 7, 8, 9, 12, 17, 18, 19] as const
const MIN_SESSIONS_PER_DAY = 3
const MAX_SESSIONS_PER_DAY = 6

function hashString(input: string): number {
  let hash = 2166136261 // FNV-1a 32-bit offset basis
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index)
    hash = Math.imul(hash, 16777619)
  }
  return hash >>> 0
}

function mulberry32(seed: number): () => number {
  let state = seed
  return () => {
    state = (state + 0x6d2b79f5) | 0
    let value = Math.imul(state ^ (state >>> 15), 1 | state)
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296
  }
}

export function getSessionsForDate(dateKey: string): Session[] {
  return FACILITIES.flatMap((facility) => {
    const random = mulberry32(hashString(`${dateKey}|${facility.id}`))
    const sessionCount =
      MIN_SESSIONS_PER_DAY +
      Math.floor(random() * (MAX_SESSIONS_PER_DAY - MIN_SESSIONS_PER_DAY + 1))

    const remainingHours: number[] = [...START_HOURS]
    const chosenHours: number[] = []
    while (chosenHours.length < sessionCount && remainingHours.length > 0) {
      const index = Math.floor(random() * remainingHours.length)
      const [hour] = remainingHours.splice(index, 1)
      chosenHours.push(hour)
    }
    chosenHours.sort((a, b) => a - b)

    return chosenHours.map((hour, index) => {
      const classType =
        CLASS_TYPES[Math.floor(random() * CLASS_TYPES.length)]
      return {
        id: `${facility.id}-${dateKey}-${index}`,
        facilityId: facility.id,
        classTypeId: classType.id,
        startsAt: wallTimeInZoneToUtc(
          dateKey,
          hour,
          0,
          facility.timeZone
        ).toISOString(),
        durationMinutes: 60,
      }
    })
  })
}

export function getClassTypes(): readonly ClassType[] {
  return CLASS_TYPES
}
