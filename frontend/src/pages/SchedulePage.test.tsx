import { render, screen, waitFor, within } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import { MemoryRouter } from 'react-router'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import SchedulePage from './SchedulePage'
import { formatDayLabel } from '../lib/date-time'
import type { Session } from '../features/schedule/types'
import type { ClassType } from '../lib/api-types'
import i18n from '../i18n/i18n'

const MOCK_CLASS_TYPES: readonly ClassType[] = [
  { id: 10, name: 'Yoga' },
  { id: 20, name: 'Spinning' },
]

const MOCK_SESSIONS: readonly Session[] = [
  { id: '1', facilityId: 9, activityName: 'Yoga', activityId: 10, startsAt: '2026-07-18T12:00:00.000Z' },
  { id: '2', facilityId: 9, activityName: 'Spinning', activityId: 20, startsAt: '2026-07-18T14:00:00.000Z' },
]

const DEFAULT_SCHEDULE_RESULT = {
  sessions: [] as readonly Session[],
  classTypes: [] as readonly ClassType[],
  isLoading: false,
  isBackgroundLoading: false,
  error: null as string | null,
  retryCount: 0,
  maxRetries: 3,
  manualRetry: vi.fn(),
}

let scheduleReturn = { ...DEFAULT_SCHEDULE_RESULT }

vi.mock('../hooks/useCities', () => ({
  useCities: () => ({ cities: [], isLoading: false, error: null }),
}))

vi.mock('../hooks/useFacilities', () => ({
  useFacilities: () => ({ facilities: [], isLoading: false, error: null }),
}))

vi.mock('../hooks/useSchedule', () => ({
  useSchedule: () => scheduleReturn,
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
    scheduleReturn = { ...DEFAULT_SCHEDULE_RESULT }
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

  describe('class-type filter', () => {
    it('shows only All option when no class types are available', () => {
      renderPage()

      const classTypeSelect = screen.getByLabelText(/Clase|Class/)
      const options = classTypeSelect.querySelectorAll('option')
      expect(options).toHaveLength(1)
      expect(options[0].textContent).toMatch(/Todas|All/)
    })

    it('is disabled when no class types are available', () => {
      renderPage()

      const classTypeSelect = screen.getByLabelText(/Clase|Class/)
      expect(classTypeSelect).toBeDisabled()
    })

    it('renders class type options from schedule response', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const classTypeSelect = screen.getByLabelText(/Clase|Class/)
      const options = classTypeSelect.querySelectorAll('option')
      expect(options).toHaveLength(3)
      expect(options[1].textContent).toBe('Yoga')
      expect(options[2].textContent).toBe('Spinning')
    })

    it('is enabled when class types are available', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const classTypeSelect = screen.getByLabelText(/Clase|Class/)
      expect(classTypeSelect).not.toBeDisabled()
    })

    it('filters sessions when a class type is selected', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      expect(within(sessionList).getByText('Yoga')).toBeInTheDocument()
      expect(within(sessionList).getByText('Spinning')).toBeInTheDocument()

      const classTypeSelect = screen.getByLabelText(/Clase|Class/)
      await user.selectOptions(classTypeSelect, '10')

      await waitFor(() => {
        expect(within(sessionList).getByText('Yoga')).toBeInTheDocument()
      })
      expect(within(sessionList).queryByText('Spinning')).not.toBeInTheDocument()
    })
  })
})
