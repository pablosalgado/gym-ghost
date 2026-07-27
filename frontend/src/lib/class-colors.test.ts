import { describe, expect, it } from 'vitest'
import { classNameToColor } from './class-colors'

describe('classNameToColor', () => {
  it('returns an HSLA string', () => {
    const result = classNameToColor('STRIDE')
    expect(result).toMatch(/^hsla\(\d+,\s*\d+%,\s*\d+%,\s*[\d.]+\)$/)
  })

  it('is deterministic — same name always produces same color', () => {
    expect(classNameToColor('STRIDE')).toBe(classNameToColor('STRIDE'))
    expect(classNameToColor('SAVAGE')).toBe(classNameToColor('SAVAGE'))
    expect(classNameToColor('TONIC')).toBe(classNameToColor('TONIC'))
  })

  it('produces different colors for different names', () => {
    const names = ['STRIDE', 'SAVAGE', 'TONIC', 'JAB', 'SOLIDO', 'LESTROIS', 'BEATS', 'BUUM', 'GIRO']
    const colors = names.map(classNameToColor)
    const unique = new Set(colors)
    // All nine should be distinct
    expect(unique.size).toBe(names.length)
  })

  it('hue is always in [0, 359]', () => {
    for (let i = 0; i < 100; i++) {
      const color = classNameToColor(`test-class-${i}`)
      const match = color.match(/^hsla\((\d+)/)
      expect(match).not.toBeNull()
      const hue = Number(match![1])
      expect(hue).toBeGreaterThanOrEqual(0)
      expect(hue).toBeLessThan(360)
    }
  })

  it('uses fixed pastel saturation and lightness', () => {
    const color = classNameToColor('AnyClass')
    // HSLA(saturation%, lightness%, alpha)
    const match = color.match(/^hsla\(\d+,\s*(\d+)%,\s*(\d+)%,\s*([\d.]+)\)$/)
    expect(match).not.toBeNull()
    expect(match![1]).toBe('50')
    expect(match![2]).toBe('85')
    expect(Number(match![3])).toBeLessThan(1) // alpha < 1 = transparency
    expect(Number(match![3])).toBeGreaterThan(0)
  })

  it('handles empty string', () => {
    const result = classNameToColor('')
    expect(result).toBe('hsla(0, 50%, 85%, 0.4)')
    expect(classNameToColor('')).toBe(classNameToColor(''))
  })

  it('handles special characters', () => {
    const color = classNameToColor('STRIDE+')
    expect(color).toMatch(/^hsla\(\d+,\s*\d+%,\s*\d+%,\s*[\d.]+\)$/)
    // Should differ from plain STRIDE
    expect(color).not.toBe(classNameToColor('STRIDE'))
  })

  it('handles very long names without crashing', () => {
    const longName = 'A'.repeat(1000)
    const color = classNameToColor(longName)
    expect(() => classNameToColor(longName)).not.toThrow()
    expect(color).toMatch(/^hsla\(\d+,\s*\d+%,\s*\d+%,\s*[\d.]+\)$/)
  })
})
