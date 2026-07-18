import { Link } from 'react-router'
import { useTranslation } from 'react-i18next'

export default function LandingPage() {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col items-center gap-8 px-4 py-12">
      <div className="text-center">
        <h1 className="text-3xl font-bold">{t('landing.title')}</h1>
        <p className="mt-2 text-gray-600">{t('landing.subtitle')}</p>
      </div>
      <Link
        to="/schedule"
        className="block w-full min-h-11 rounded-lg border border-gray-300 p-6 hover:border-blue-600 hover:shadow-sm sm:max-w-sm"
      >
        <h2 className="text-xl font-semibold">{t('landing.ctaTitle')}</h2>
        <p className="mt-1 text-sm text-gray-600">
          {t('landing.ctaDescription')}
        </p>
      </Link>
    </div>
  )
}
