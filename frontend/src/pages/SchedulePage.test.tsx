import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import SchedulePage from './SchedulePage'
import { formatDayLabel } from '../lib/date-time'
import i18n from '../i18n/i18n'
import { getSessionsForDate } from '../features/schedule/mockSchedule'
import { useCities } from '../hooks/useCities'
import { useFacilities } from '../hooks/useFacilities'

vi.mock('../features/schedule/mockSchedule', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../features/schedule/mockSchedule')>()
  return {
    ...actual,
    getSessionsForDate: vi.fn(actual.getSessionsForDate),
  }
})

vi.mock('../hooks/useCities')
vi.mock('../hooks/useFacilities')

const mockedGetSessions = vi.mocked(getSessionsForDate)
const mockedUseCities = vi.mocked(useCities)
const mockedUseFacilities = vi.mocked(useFacilities)

const FROZEN_UTC = '2026-07-18T02:30:00.000Z'

function renderPage() {
  return render(
    <MemoryRouter>
      <SchedulePage />
    </MemoryRouter>
  )
}

describe('SchedulePage', () => {
  beforeEach(() => {
    vi.setSystemTime(new Date(FROZEN_UTC))
    mockedGetSessions.mockClear()
    mockedUseCities.mockReturnValue({ cities: [], isLoading: false, error: null })
    mockedUseFacilities.mockReturnValue({ facilities: [], isLoading: false, error: null })
  })

  it('renders 14 day buttons', () => {
    renderPage()

    const buttons = screen.getAllByRole('button')
    expect(buttons).toHaveLength(14)
  })

  it('shows Bogotá today as the first day (Jul 17 at frozen time)', () => {
    renderPage()

    const locale = i18n.resolvedLanguage ?? 'es-CO'
    const { weekday, day } = formatDayLabel('2026-07-17', locale)

    expect(
      screen.getByRole('button', { name: new RegExp(`${weekday}.*${day}`, 'i') })
    ).toBeInTheDocument()
  })

  it('city select shows cities from API', () => {
    mockedUseCities.mockReturnValue({
      cities: [
        { id: 1, city_name: 'BOGOTÁ, D.C.' },
        { id: 2, city_name: 'MEDELLÍN' },
      ],
      isLoading: false,
      error: null,
    })

    renderPage()

    const citySelect = screen.getByLabelText(/Ciudad|City/)
    const options = citySelect.querySelectorAll('option')
    expect(options).toHaveLength(3)
    expect(options[0].textContent).toMatch(/All|Todas/)
    expect(options[1].textContent).toBe('BOGOTÁ, D.C.')
    expect(options[2].textContent).toBe('MEDELLÍN')
  })

  it('facility select shows facilities from API', () => {
    mockedUseFacilities.mockReturnValue({
      facilities: [
        { id: 1, display_name: 'Chapinero', city_id: 1 },
        { id: 2, display_name: 'Zona T', city_id: 1 },
      ],
      isLoading: false,
      error: null,
    })

    renderPage()

    const facilitySelect = screen.getByLabelText(/Sede|Facility/)
    const options = facilitySelect.querySelectorAll('option')
    expect(options).toHaveLength(3)
    expect(options[0].textContent).toMatch(/All|Todas/)
    expect(options[1].textContent).toBe('Chapinero')
    expect(options[2].textContent).toBe('Zona T')
  })

  it('renders empty state when no sessions match', () => {
    mockedGetSessions.mockReturnValueOnce([])

    renderPage()

    expect(
      screen.getByText(/No hay clases|No classes/)
    ).toBeInTheDocument()
  })

  it('shows session count that matches filtered results', () => {
    renderPage()

    const initialCount = screen.getAllByRole('listitem').length
    expect(initialCount).toBeGreaterThan(0)

    const classSelect = screen.getByLabelText(/Clase|Class/)
    fireEvent.change(classSelect, { target: { value: 'boxing' } })

    const filteredCount = screen.getAllByRole('listitem').length
    expect(filteredCount).toBeLessThanOrEqual(initialCount)
  })
})
