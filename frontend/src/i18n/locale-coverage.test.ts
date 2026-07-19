import { describe, expect, it } from 'vitest'
import esCO from './locales/es-CO/common.json'
import enUS from './locales/en-US/common.json'

function collectKeys(obj: Record<string, unknown>, prefix = ''): string[] {
  return Object.entries(obj).flatMap(([key, value]) => {
    const fullKey = prefix ? `${prefix}.${key}` : key
    if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      return collectKeys(value as Record<string, unknown>, fullKey)
    }
    return [fullKey]
  })
}

describe('locale key parity', () => {
  it('es-CO and en-US define exactly the same key set', () => {
    const esKeys = collectKeys(esCO).sort()
    const enKeys = collectKeys(enUS).sort()
    expect(esKeys).toEqual(enKeys)
  })
})

describe('locale coverage', () => {
  it('every schedule.* key resolves to a string different from the key in es-CO', () => {
    const keys = collectKeys(esCO).filter((k) => k.startsWith('schedule.'))
    for (const key of keys) {
      const segments = key.split('.')
      let value: unknown = esCO
      for (const segment of segments) {
        value = (value as Record<string, unknown>)[segment]
      }
      expect(typeof value).toBe('string')
      expect(value).not.toBe(key)
    }
  })

  it('every schedule.* key resolves to a string different from the key in en-US', () => {
    const keys = collectKeys(enUS).filter((k) => k.startsWith('schedule.'))
    for (const key of keys) {
      const segments = key.split('.')
      let value: unknown = enUS
      for (const segment of segments) {
        value = (value as Record<string, unknown>)[segment]
      }
      expect(typeof value).toBe('string')
      expect(value).not.toBe(key)
    }
  })
})
