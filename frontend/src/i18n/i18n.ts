import i18n from 'i18next'
import LanguageDetector from 'i18next-browser-languagedetector'
import { initReactI18next } from 'react-i18next'
import { defaultNS, resources } from './resources'

export const SUPPORTED_LANGUAGES = ['es-CO', 'en-US'] as const
export const DEFAULT_LANGUAGE = 'es-CO'
export const LANGUAGE_STORAGE_KEY = 'gym-ghost:lng'

void i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    defaultNS,
    ns: [defaultNS],
    supportedLngs: [...SUPPORTED_LANGUAGES],
    fallbackLng: DEFAULT_LANGUAGE,
    nonExplicitSupportedLngs: false,
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
      lookupLocalStorage: LANGUAGE_STORAGE_KEY,
    },
    interpolation: { escapeValue: false },
    returnNull: false,
  })

function syncHtmlLang(language: string): void {
  document.documentElement.lang = language
}

i18n.on('languageChanged', syncHtmlLang)
syncHtmlLang(i18n.resolvedLanguage ?? i18n.language)

export default i18n
