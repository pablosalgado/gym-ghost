import { useTranslation } from 'react-i18next'

export default function SchedulePlaceholderPage() {
  const { t } = useTranslation()

  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-2 px-4">
      <h1 className="text-2xl font-bold">{t('schedule.placeholder.title')}</h1>
      <p className="text-gray-600">{t('schedule.placeholder.comingSoon')}</p>
    </div>
  )
}
