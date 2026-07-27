import { useEffect, useMemo, useRef, useState } from 'react'
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
import { useBookingRequest } from '../hooks/useBookingRequest'
import BookingStatusBadge from '../components/BookingStatusBadge'

const DEFAULT_CITY_NAME = 'BOGOTÁ, D.C.'
const DEFAULT_FACILITY_NAME = 'C.C Parque La Colina'

export default function SchedulePage() {
  const { t } = useTranslation()
  const locale = i18n.resolvedLanguage ?? 'es-CO'
  const days = useMemo(() => windowFromToday(14, DEFAULT_TIME_ZONE), [])

  const [selectedDate, setSelectedDate] = useState(() => days[0])
  const [cityId, setCityId] = useState<number | undefined>()
  const [facilityId, setFacilityId] = useState<number | undefined>()
  const [activityId, setActivityId] = useState<number | undefined>()

  const { cities, isLoading: citiesLoading } = useCities()
  const { facilities: facilitiesForCity, isLoading: facilitiesLoading } = useFacilities(cityId)
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

  const booking = useBookingRequest()
  const [createTargetId, setCreateTargetId] = useState<number | null>(null)

  const cityPreselected = useRef(false)
  const facilityPreselected = useRef(false)

  useEffect(() => {
    if (cityId !== undefined || cityPreselected.current || citiesLoading || cities.length === 0) return
    const match = cities.find((c) => c.city_name === DEFAULT_CITY_NAME)
    if (match) {
      cityPreselected.current = true
      setCityId(match.id)
    }
  }, [cities, citiesLoading, cityId])

  useEffect(() => {
    if (facilityId !== undefined || facilityPreselected.current || facilitiesLoading || facilitiesForCity.length === 0) return
    const match = facilitiesForCity.find((f) => f.display_name === DEFAULT_FACILITY_NAME)
    if (match) {
      facilityPreselected.current = true
      setFacilityId(match.id)
    }
  }, [facilitiesForCity, facilitiesLoading, facilityId])

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

  async function handleReserve(scheduleEntryId: number) {
    setCreateTargetId(scheduleEntryId)
    await booking.create(scheduleEntryId)
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
          {sessions.map((session) => {
            const sessionId = Number(session.id)
            const isTarget = createTargetId === sessionId

            let activeBookingRequest = session.bookingRequest ?? null

            if (booking.bookingRequest && booking.bookingRequest.schedule_entry_id === sessionId) {
              activeBookingRequest = booking.bookingRequest
            }

            return (
            <li key={session.id} className="flex items-center gap-4 px-4 py-3">
              <span className="w-20 shrink-0 text-sm font-medium text-gray-900">
                {formatTimeOfDay(session.startsAt, locale, DEFAULT_TIME_ZONE)}
              </span>
              <div className="flex-1 min-w-0">
                <p className="font-medium truncate">{session.activityName}</p>
                <p className="text-sm text-gray-600">
                  {session.facilityId}
                </p>
              </div>
              <div className="shrink-0">
                {activeBookingRequest && activeBookingRequest.status === 'pending' && (
                  <BookingStatusBadge
                    status="pending"
                    pendingLabel={t('schedule.booking.reserveAt', { time: formatTimeOfDay(activeBookingRequest.booking_window_opens_at, locale, DEFAULT_TIME_ZONE) })}
                  />
                )}

                {activeBookingRequest && activeBookingRequest.status === 'booked' && (
                  <BookingStatusBadge status="booked" />
                )}

                {activeBookingRequest && activeBookingRequest.status === 'failed' && (
                  <BookingStatusBadge
                    status="failed"
                    onRetry={() => handleReserve(sessionId)}
                    isLoading={booking.isLoading}
                    retryLabel={t('schedule.booking.retry')}
                  />
                )}

                {!activeBookingRequest && isTarget && booking.error && (
                  <div className="flex items-center gap-2">
                    <BookingStatusBadge status="available" />
                    <span className="text-sm text-red-600">{booking.error}</span>
                    <button
                      type="button"
                      onClick={() => handleReserve(sessionId)}
                      disabled={booking.isLoading}
                      className="min-h-11 min-w-11 rounded bg-red-100 px-3 py-2 text-sm font-medium text-red-700 hover:bg-red-200 disabled:opacity-50"
                    >
                      {t('schedule.booking.retry')}
                    </button>
                  </div>
                )}

                {!activeBookingRequest && !(isTarget && booking.error) && (
                  <div className="flex items-center gap-2">
                    <BookingStatusBadge status="available" />
                    <button
                      type="button"
                      onClick={() => handleReserve(sessionId)}
                      disabled={booking.isLoading}
                      className="min-h-11 min-w-11 rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                    >
                      {booking.isLoading ? t('common.loading') : t('schedule.booking.reserve')}
                    </button>
                  </div>
                )}
              </div>
            </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
