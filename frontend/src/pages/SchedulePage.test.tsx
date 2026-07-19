import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import SchedulePage from './SchedulePage'
import { formatDayLabel } from '../lib/date-time'
import i18n from '../i18n/i18n'
import { getSessionsForDate } from '../features/schedule/mockSchedule'

vi.mock('../features/schedule/mockSchedule', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../features/schedule/mockSchedule')>()
  return {
    ...actual,
    getSessionsForDate: vi.fn(actual.getSessionsForDate),
  }
})

const mockedGetSessions = vi.mocked(getSessionsForDate)

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

  it('filters sessions by facility', () => {
    renderPage()

    const facilitySelect = screen.getByLabelText(/Sede|Facility/)
    fireEvent.change(facilitySelect, { target: { value: 'chapinero' } })

    const listItems = screen.getAllByRole('listitem')
    for (const item of listItems) {
      expect(item.textContent).toContain('Chapinero')
    }
  })

  it('resets facility selection when city changes', () => {
    renderPage()

    const facilitySelect = screen.getByLabelText(/Sede|Facility/)
    fireEvent.change(facilitySelect, { target: { value: 'chapinero' } })

    const citySelect = screen.getByLabelText(/Ciudad|City/)
    fireEvent.change(citySelect, { target: { value: 'medellin' } })

    expect(facilitySelect).toHaveValue('')
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
