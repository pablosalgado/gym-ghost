import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import i18n from '../i18n/i18n'
import {
  DEFAULT_TIME_ZONE,
  formatDayLabel,
  formatTimeOfDay,
  windowFromToday,
} from '../lib/date-time'
import { FACILITIES, type CityId, type ClassTypeId, type FacilityId } from '../features/schedule/types'
import {
  getClassTypes,
  getCities,
  getFacilities,
  getSessionsForDate,
} from '../features/schedule/mockSchedule'
import { filterSessions } from '../features/schedule/filterSessions'

export default function SchedulePage() {
  const { t } = useTranslation()
  const locale = i18n.resolvedLanguage ?? 'es-CO'
  const days = useMemo(() => windowFromToday(14, DEFAULT_TIME_ZONE), [])

  const [selectedDate, setSelectedDate] = useState(() => days[0])
  const [cityId, setCityId] = useState<CityId | undefined>()
  const [facilityId, setFacilityId] = useState<FacilityId | undefined>()
  const [classTypeId, setClassTypeId] = useState<ClassTypeId | undefined>()

  const cities = getCities()
  const facilitiesForCity = useMemo(() => getFacilities(cityId), [cityId])
  const classTypes = getClassTypes()

  const sessions = useMemo(() => {
    const all = getSessionsForDate(selectedDate)
    return filterSessions(all, { cityId, facilityId, classTypeId }, FACILITIES)
  }, [selectedDate, cityId, facilityId, classTypeId])

  function handleCityChange(newCityId: string) {
    const value = (newCityId || undefined) as CityId | undefined
    setCityId(value)
    setFacilityId(undefined)
  }

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
                {t(`schedule.cities.${city.id}` as const)}
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
            onChange={(event) => setFacilityId((event.target.value || undefined) as FacilityId | undefined)}
            className="min-h-11 rounded border border-gray-300 px-3 py-2"
          >
            <option value="">{t('schedule.filter.all')}</option>
            {facilitiesForCity.map((facility) => (
              <option key={facility.id} value={facility.id}>
                {t(`schedule.facilities.${facility.id}` as const)}
              </option>
            ))}
          </select>
        </div>

        <div className="flex flex-col gap-1">
          <label htmlFor="class-filter" className="text-sm font-medium text-gray-700">
            {t('schedule.filter.classType')}
          </label>
          <select
            id="class-filter"
            value={classTypeId ?? ''}
            onChange={(event) => setClassTypeId((event.target.value || undefined) as ClassTypeId | undefined)}
            className="min-h-11 rounded border border-gray-300 px-3 py-2"
          >
            <option value="">{t('schedule.filter.all')}</option>
            {classTypes.map((ct) => (
              <option key={ct.id} value={ct.id}>
                {t(`schedule.classes.${ct.id}` as const)}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Session list */}
      {sessions.length === 0 ? (
        <p className="py-12 text-center text-gray-500">{t('schedule.emptyState')}</p>
      ) : (
        <ul className="divide-y divide-gray-200 rounded-lg border border-gray-200">
          {sessions.map((session) => {
            const facility = FACILITIES.find((f) => f.id === session.facilityId)
            return (
              <li key={session.id} className="flex items-center gap-4 px-4 py-3">
                <span className="w-20 text-sm font-medium text-gray-900">
                  {formatTimeOfDay(session.startsAt, locale, DEFAULT_TIME_ZONE)}
                </span>
                <div className="flex-1">
                  <p className="font-medium">
                    {t(`schedule.classes.${session.classTypeId}` as const)}
                  </p>
                  <p className="text-sm text-gray-600">
                    {facility
                      ? `${t(`schedule.facilities.${facility.id}` as const)} · ${t(`schedule.cities.${facility.cityId}` as const)}`
                      : session.facilityId}
                  </p>
                </div>
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
