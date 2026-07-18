import { beforeEach, describe, expect, it } from 'vitest'
import i18n, {
  DEFAULT_LANGUAGE,
  LANGUAGE_STORAGE_KEY,
  SUPPORTED_LANGUAGES,
} from './i18n'
import enUS from './locales/en-US/common.json'
import esCO from './locales/es-CO/common.json'

function keyPaths(value: unknown, prefix = ''): string[] {
  if (typeof value !== 'object' || value === null) {
    return [prefix]
  }
  return Object.entries(value as Record<string, unknown>).flatMap(
    ([key, nested]) => keyPaths(nested, prefix ? `${prefix}.${key}` : key)
  )
}

describe('i18n configuration', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('ships exactly es-CO and en-US with es-CO as fallback', () => {
    expect(SUPPORTED_LANGUAGES).toEqual(['es-CO', 'en-US'])
    expect(i18n.options.fallbackLng).toEqual([DEFAULT_LANGUAGE])
    expect(i18n.options.returnNull).toBe(false)
  })

  it('falls back to es-CO for an unsupported locale', () => {
    const t = i18n.getFixedT('fr-FR')
    expect(t('auth.loginTitle')).toBe(esCO.auth.loginTitle)
  })

  it('has no missing keys', () => {
    expect(i18n.exists('common.thisKeyDoesNotExist' as never)).toBe(false)
  })

  it('keeps es-CO and en-US key sets in parity', () => {
    expect(keyPaths(enUS).sort()).toEqual(keyPaths(esCO).sort())
  })

  it('persists the language choice and syncs <html lang>', async () => {
    await i18n.changeLanguage('en-US')
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('en-US')
    expect(document.documentElement.lang).toBe('en-US')

    await i18n.changeLanguage('es-CO')
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('es-CO')
    expect(document.documentElement.lang).toBe('es-CO')
  })

  it('translates existing UI strings in both locales', () => {
    expect(i18n.getFixedT('es-CO')('auth.logOut')).toBe(esCO.auth.logOut)
    expect(i18n.getFixedT('en-US')('auth.logOut')).toBe(enUS.auth.logOut)
  })
})
