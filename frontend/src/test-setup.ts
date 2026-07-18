import '@testing-library/jest-dom/vitest'
import { beforeEach } from 'vitest'
import i18n, { DEFAULT_LANGUAGE, LANGUAGE_STORAGE_KEY } from './i18n/i18n'

beforeEach(() => {
  localStorage.removeItem(LANGUAGE_STORAGE_KEY)
  void i18n.changeLanguage(DEFAULT_LANGUAGE)
})
