import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import SchedulePage from './SchedulePage'
import { formatDayLabel } from '../lib/date-time'
import i18n from '../i18n/i18n'

vi.mock('../hooks/useCities', () => ({
  useCities: () => ({ cities: [], isLoading: false, error: null }),
}))

vi.mock('../hooks/useFacilities', () => ({
  useFacilities: () => ({ facilities: [], isLoading: false, error: null }),
}))

vi.mock('../hooks/useSchedule', () => ({
  useSchedule: () => ({ sessions: [], isLoading: false, error: null }),
}))

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

  it('renders empty state when no sessions are available', () => {
    renderPage()

    expect(
      screen.getByText(/No hay clases|No classes/)
    ).toBeInTheDocument()
  })

  it('shows only All option in city select', () => {
    renderPage()

    const citySelect = screen.getByLabelText(/Ciudad|City/)
    const options = citySelect.querySelectorAll('option')
    expect(options).toHaveLength(1)
    expect(options[0].textContent).toMatch(/Todas|All/)
  })

  it('shows only All option in facility select', () => {
    renderPage()

    const facilitySelect = screen.getByLabelText(/Sede|Facility/)
    const options = facilitySelect.querySelectorAll('option')
    expect(options).toHaveLength(1)
    expect(options[0].textContent).toMatch(/Todas|All/)
  })

  it('shows only All option in class select', () => {
    renderPage()

    const classSelect = screen.getByLabelText(/Clase|Class/)
    const options = classSelect.querySelectorAll('option')
    expect(options).toHaveLength(1)
    expect(options[0].textContent).toMatch(/Todas|All/)
  })
})
