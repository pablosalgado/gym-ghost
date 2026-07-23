import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import i18n from '../i18n/i18n'
import {
  DEFAULT_TIME_ZONE,
  formatDayLabel,
  formatTimeOfDay,
  windowFromToday,
} from '../lib/date-time'
import { filterSessions } from '../features/schedule/filterSessions'
import { useCities } from '../hooks/useCities'
import { useFacilities } from '../hooks/useFacilities'
import { useSchedule } from '../hooks/useSchedule'

export default function SchedulePage() {
  const { t } = useTranslation()
  const locale = i18n.resolvedLanguage ?? 'es-CO'
  const days = useMemo(() => windowFromToday(14, DEFAULT_TIME_ZONE), [])

  const [selectedDate, setSelectedDate] = useState(() => days[0])
  const [cityId, setCityId] = useState<number | undefined>(1)
  const [facilityId, setFacilityId] = useState<number | undefined>(9)
  const [activityId, setActivityId] = useState<number | undefined>()

  const { cities } = useCities()
  const { facilities: facilitiesForCity } = useFacilities(cityId)
  const {
    sessions: scheduleSessions,
    classTypes,
    isLoading: scheduleLoading,
    error: scheduleError,
    isBackgroundLoading,
    retryCount,
    maxRetries,
    manualRetry,
  } = useSchedule(selectedDate, facilityId)

  // Reset activity filter when facility or date changes —
  // the previously selected class type may not exist in the new response.
  useEffect(() => {
    setActivityId(undefined)
  }, [facilityId, selectedDate])

  const sessions = useMemo(() => {
    return filterSessions(scheduleSessions, { cityId, facilityId, activityId })
  }, [scheduleSessions, cityId, facilityId, activityId])

  function handleCityChange(newCityId: string) {
    const value = newCityId ? Number(newCityId) : undefined
    setCityId(value)
    setFacilityId(undefined)
  }

  const isExhausted = retryCount >= maxRetries && scheduleSessions.length === 0

  return (
    <div className="mx-auto max-w-4xl px-3 py-6 sm:px-4">
      <h1 className="mb-4 text-2xl font-bold">{t('schedule.title')}</h1>

      {/* Day strip */}
      <div className="mb-6 flex gap-1 overflow-x-auto pb-2">
        {days.map((dateKey) => {
          const { weekday, day } = formatDayLabel(dateKey, locale, DEFAULT_TIME_ZONE)
          const isSelected = dateKey === selectedDate
          return (
            <button
              key={dateKey}
              type="button"
              onClick={() => setSelectedDate(dateKey)}
              className={`flex min-w-[3.5rem] flex-col items-center rounded-lg px-2 py-1 text-sm ${
                isSelected
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              <span className="text-xs uppercase">{weekday}</span>
              <span className="font-semibold">{day}</span>
            </button>
          )
        })}
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-wrap gap-3">
        <div className="flex flex-col gap-1">
          <label htmlFor="city-filter" className="text-sm font-medium text-gray-700">
            {t('schedule.filter.city')}
          </label>
          <select
            id="city-filter"
            value={cityId ?? ''}
            onChange={(event) => handleCityChange(event.target.value)}
            className="min-h-11 rounded border border-gray-300 px-3 py-2"
          >
            <option value="">{t('schedule.filter.all')}</option>
            {cities.map((city) => (
              <option key={city.id} value={city.id}>
                {city.city_name}
              </option>
            ))}
          </select>
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="facility-filter" className="text-sm font-medium text-gray-700">
            {t('schedule.filter.facility')}
          </label>
          <select
            id="facility-filter"
            value={facilityId ?? ''}
            onChange={(event) => setFacilityId(event.target.value ? Number(event.target.value) : undefined)}
            className="min-h-11 rounded border border-gray-300 px-3 py-2"
          >
            <option value="">{t('schedule.filter.all')}</option>
            {facilitiesForCity.map((facility) => (
              <option key={facility.id} value={facility.id}>
                {facility.display_name}
              </option>
            ))}
          </select>
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="class-type-filter" className="text-sm font-medium text-gray-700">
            {t('schedule.filter.classType')}
          </label>
          <select
            id="class-type-filter"
            value={activityId ?? ''}
            onChange={(event) => setActivityId(event.target.value ? Number(event.target.value) : undefined)}
            disabled={classTypes.length === 0}
            className="min-h-11 rounded border border-gray-300 px-3 py-2 disabled:opacity-50"
          >
            <option value="">{t('schedule.filter.all')}</option>
            {classTypes.map((ct) => (
              <option key={ct.id} value={ct.id}>
                {ct.name}
              </option>
            ))}
          </select>
        </div>

      </div>

      {/* Session list / states */}
      {scheduleError !== null ? (
        <p className="py-12 text-center text-red-600">{scheduleError}</p>
      ) : scheduleLoading ? (
        <p className="py-12 text-center text-gray-500">{t('common.loading')}</p>
      ) : sessions.length === 0 ? (
        <div className="py-12 text-center">
          {isBackgroundLoading ? (
            <p className="text-gray-400">{t('common.loading')}</p>
          ) : isExhausted ? (
            <div>
              <p className="text-gray-500 mb-4">{t('schedule.emptyState')}</p>
              <button
                type="button"
                onClick={manualRetry}
                className="min-h-11 rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
              >
                {t('schedule.retry')}
              </button>
            </div>
          ) : (
            <p className="text-gray-500">{t('schedule.emptyState')}</p>
          )}
        </div>
      ) : (
        <ul className="divide-y divide-gray-200 rounded-lg border border-gray-200">
          {sessions.map((session) => (
            <li key={session.id} className="flex items-center gap-4 px-4 py-3">
              <span className="w-20 text-sm font-medium text-gray-900">
                {formatTimeOfDay(session.startsAt, locale, DEFAULT_TIME_ZONE)}
              </span>
              <div className="flex-1">
                <p className="font-medium">
                  {session.activityName}
                </p>
                <p className="text-sm text-gray-600">
                  {session.facilityId}
                </p>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
