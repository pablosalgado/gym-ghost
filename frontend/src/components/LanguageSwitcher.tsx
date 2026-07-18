import { useTranslation } from 'react-i18next'
import { DEFAULT_LANGUAGE, SUPPORTED_LANGUAGES } from '../i18n/i18n'

type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number]

export default function LanguageSwitcher() {
  const { t, i18n } = useTranslation()

  return (
    <label className="flex items-center gap-2 text-sm font-medium">
      <span>{t('language.switcherLabel')}</span>
      <select
        value={i18n.resolvedLanguage ?? DEFAULT_LANGUAGE}
        onChange={(event) =>
          void i18n.changeLanguage(event.target.value as SupportedLanguage)
        }
        className="min-h-11 rounded border border-gray-300 px-3 py-2"
      >
        {SUPPORTED_LANGUAGES.map((language) => (
          <option key={language} value={language}>
            {t(`language.${language}`)}
          </option>
        ))}
      </select>
    </label>
  )
}
