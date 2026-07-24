import { render, screen, waitFor, within } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import { MemoryRouter } from 'react-router'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import SchedulePage from './SchedulePage'
import { formatDayLabel } from '../lib/date-time'
import type { Session } from '../features/schedule/types'
import type { ClassType, BookingRequest, City, Facility } from '../lib/api-types'
import i18n from '../i18n/i18n'

const MOCK_CLASS_TYPES: readonly ClassType[] = [
  { id: 10, name: 'Yoga' },
  { id: 20, name: 'Spinning' },
]

const MOCK_SESSIONS: readonly Session[] = [
  { id: '1', facilityId: 9, activityName: 'Yoga', activityId: 10, startsAt: '2026-07-18T12:00:00.000Z' },
  { id: '2', facilityId: 9, activityName: 'Spinning', activityId: 20, startsAt: '2026-07-18T14:00:00.000Z' },
]

const MOCK_BOOKING_PENDING: BookingRequest = {
  id: 100,
  schedule_entry_id: 1,
  status: 'pending',
  booking_window_opens_at: '2026-07-18T10:00:00.000Z',
}

const MOCK_BOOKING_BOOKED: BookingRequest = {
  id: 101,
  schedule_entry_id: 1,
  status: 'booked',
  booking_window_opens_at: '2026-07-18T10:00:00.000Z',
}

const MOCK_BOOKING_FAILED: BookingRequest = {
  id: 102,
  schedule_entry_id: 1,
  status: 'failed',
  booking_window_opens_at: '2026-07-18T10:00:00.000Z',
}

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

let citiesReturn: { cities: readonly City[]; isLoading: boolean; error: string | null } = {
  cities: [],
  isLoading: false,
  error: null,
}

let facilitiesReturn: { facilities: readonly Facility[]; isLoading: boolean; error: string | null } = {
  facilities: [],
  isLoading: false,
  error: null,
}

vi.mock('../hooks/useCities', () => ({
  useCities: () => citiesReturn,
}))

vi.mock('../hooks/useFacilities', () => ({
  useFacilities: () => facilitiesReturn,
}))

let bookingReturn = {
  create: vi.fn().mockResolvedValue(undefined) as (scheduleEntryId: number) => Promise<void>,
  isLoading: false,
  error: null as string | null,
  bookingRequest: null as BookingRequest | null,
}

vi.mock('../hooks/useSchedule', () => ({
  useSchedule: () => scheduleReturn,
}))

vi.mock('../hooks/useBookingRequest', () => ({
  useBookingRequest: () => bookingReturn,
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
    citiesReturn = { cities: [], isLoading: false, error: null }
    facilitiesReturn = { facilities: [], isLoading: false, error: null }
    bookingReturn = {
      create: vi.fn().mockResolvedValue(undefined),
      isLoading: false,
      error: null,
      bookingRequest: null,
    }
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

  it('displays city error when useCities returns an error and is not loading', () => {
    citiesReturn = { cities: [], isLoading: false, error: 'Not authenticated' }

    renderPage()

    expect(screen.getByText('Not authenticated')).toBeInTheDocument()
  })

  it('displays facility error when useFacilities returns an error and is not loading', () => {
    facilitiesReturn = { facilities: [], isLoading: false, error: 'Network error' }

    renderPage()

    expect(screen.getByText('Network error')).toBeInTheDocument()
  })

  it('does not display city error while still loading', () => {
    citiesReturn = { cities: [], isLoading: true, error: 'Not authenticated' }

    renderPage()

    expect(screen.queryByText('Not authenticated')).not.toBeInTheDocument()
  })

  it('does not display facility error while still loading', () => {
    facilitiesReturn = { facilities: [], isLoading: true, error: 'Network error' }

    renderPage()

    expect(screen.queryByText('Network error')).not.toBeInTheDocument()
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

  describe('booking state', () => {
    it('renders Reserve button for sessions without a booking request', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const sessionList = screen.getByRole('list')
      const reserveButtons = within(sessionList).getAllByRole('button', { name: /Reservar|Reserve/ })
      expect(reserveButtons).toHaveLength(2)
    })

    it('calls useBookingRequest.create when Reserve button is clicked', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const reserveButtons = within(sessionList).getAllByRole('button', { name: /Reservar|Reserve/ })
      await user.click(reserveButtons[0])

      expect(bookingReturn.create).toHaveBeenCalledWith(1)
    })

    it('renders pending state with clock icon and reserve time', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_PENDING },
          MOCK_SESSIONS[1],
        ],
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const sessionList = screen.getByRole('list')
      expect(within(sessionList).getByText(/Reservas a las|Reserves at/)).toBeInTheDocument()

      const reserveButtons = within(sessionList).queryAllByRole('button', { name: /Reservar|Reserve/ })
      expect(reserveButtons).toHaveLength(1)
    })

    it('renders booked state with green checkmark', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_BOOKED },
          MOCK_SESSIONS[1],
        ],
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const sessionList = screen.getByRole('list')
      expect(within(sessionList).getByLabelText('Booked')).toBeInTheDocument()

      expect(within(sessionList).getByRole('button', { name: /Reservar|Reserve/ })).toBeInTheDocument()
    })

    it('renders failed state with warning icon and Retry button', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_FAILED },
        ],
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const sessionList = screen.getByRole('list')
      expect(within(sessionList).getByRole('button', { name: /Reintentar|Retry/ })).toBeInTheDocument()
    })

    it('disables Reserve button when booking is loading', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        isLoading: true,
        error: null,
        bookingRequest: null,
      }

      renderPage()

      const sessionList = screen.getByRole('list')
      const buttons = within(sessionList).getAllByRole('button', { name: /Cargando|Loading/ })
      expect(buttons).toHaveLength(2)
      buttons.forEach((btn) => {
        expect(btn).toBeDisabled()
      })
    })

    it('shows error and Retry button on the targeted row after failed create', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        isLoading: false,
        error: 'Schedule entry is in the past.',
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const reserveButtons = within(sessionList).getAllByRole('button', { name: /Reservar|Reserve/ })
      await user.click(reserveButtons[0])

      expect(within(sessionList).getByText('Schedule entry is in the past.')).toBeInTheDocument()
      expect(within(sessionList).getByRole('button', { name: /Reintentar|Retry/ })).toBeInTheDocument()
    })

    it('optimistically shows pending state from hook bookingRequest after create succeeds', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        isLoading: false,
        error: null,
        bookingRequest: MOCK_BOOKING_PENDING,
      }

      renderPage()

      const sessionList = screen.getByRole('list')
      expect(within(sessionList).getByText(/Reservas a las|Reserves at/)).toBeInTheDocument()

      expect(within(sessionList).getByRole('button', { name: /Reservar|Reserve/ })).toBeInTheDocument()
    })
  })
})
