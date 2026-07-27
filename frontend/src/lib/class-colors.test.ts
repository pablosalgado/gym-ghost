import { describe, expect, it } from 'vitest'
import { classColors } from './class-colors'

describe('classColors', () => {
  it('returns border and background as HSLA strings', () => {
    const result = classColors('STRIDE')
    expect(result).toHaveProperty('border')
    expect(result).toHaveProperty('background')
    expect(result.border).toMatch(/^hsla\(\d+,\s*\d+%,\s*\d+%,\s*[\d.]+\)$/)
    expect(result.background).toMatch(/^hsla\(\d+,\s*\d+%,\s*\d+%,\s*[\d.]+\)$/)
  })

  it('border and background share the same hue', () => {
    for (const name of ['STRIDE', 'SAVAGE', 'TONIC']) {
      const { border, background } = classColors(name)
      const borderHue = Number(border.match(/^hsla\((\d+)/)![1])
      const bgHue = Number(background.match(/^hsla\((\d+)/)![1])
      expect(borderHue).toBe(bgHue)
    }
  })

  it('border is solid (alpha 1) and background is translucent', () => {
    const { border, background } = classColors('STRIDE')
    const borderAlpha = Number(border.match(/,\s*([\d.]+)\)$/)![1])
    const bgAlpha = Number(background.match(/,\s*([\d.]+)\)$/)![1])
    expect(borderAlpha).toBe(1)
    expect(bgAlpha).toBeLessThan(1)
    expect(bgAlpha).toBeGreaterThan(0)
  })

  it('border is darker than background', () => {
    const { border, background } = classColors('STRIDE')
    const borderLight = Number(border.match(/,\s*\d+%,\s*(\d+)%/)![1])
    const bgLight = Number(background.match(/,\s*\d+%,\s*(\d+)%/)![1])
    expect(borderLight).toBeLessThan(bgLight)
  })

  it('is deterministic — same name always produces the same colors', () => {
    expect(classColors('STRIDE')).toEqual(classColors('STRIDE'))
    expect(classColors('SAVAGE')).toEqual(classColors('SAVAGE'))
  })

  it('produces different hues for different names', () => {
    const names = ['STRIDE', 'SAVAGE', 'TONIC', 'JAB', 'SOLIDO', 'LESTROIS', 'BEATS', 'BUUM', 'GIRO']
    const hues = names.map((n) => Number(classColors(n).border.match(/^hsla\((\d+)/)![1]))
    expect(new Set(hues).size).toBe(names.length)
  })

  it('hue is always in [0, 359]', () => {
    for (let i = 0; i < 100; i++) {
      const { border } = classColors(`test-class-${i}`)
      const hue = Number(border.match(/^hsla\((\d+)/)![1])
      expect(hue).toBeGreaterThanOrEqual(0)
      expect(hue).toBeLessThan(360)
    }
  })

  it('handles empty string', () => {
    const result = classColors('')
    expect(result).toEqual(classColors(''))
    expect(result.border).toBe('hsla(0, 55%, 65%, 1)')
  })

  it('handles special characters', () => {
    const normal = classColors('STRIDE')
    const special = classColors('STRIDE+')
    expect(special.border).not.toBe(normal.border)
  })

  it('handles very long names without crashing', () => {
    const longName = 'A'.repeat(1000)
    expect(() => classColors(longName)).not.toThrow()
    expect(classColors(longName).border).toMatch(/^hsla\(\d+/)
  })
})
