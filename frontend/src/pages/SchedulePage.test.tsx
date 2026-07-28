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
  cancel: vi.fn().mockResolvedValue(true) as (bookingRequestId: number) => Promise<boolean>,
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
      cancel: vi.fn().mockResolvedValue(true),
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
    const { container } = renderPage()

    const citySelect = container.querySelector('#city-filter') as HTMLSelectElement
    const options = citySelect.querySelectorAll('option')
    expect(options).toHaveLength(1)
    expect(options[0].textContent).toMatch(/Todas|All/)
  })

  it('shows only All option in facility select', () => {
    const { container } = renderPage()

    const facilitySelect = container.querySelector('#facility-filter') as HTMLSelectElement
    const options = facilitySelect.querySelectorAll('option')
    expect(options).toHaveLength(1)
    expect(options[0].textContent).toMatch(/Todas|All/)
  })

  describe('default city and facility selection', () => {
    it('auto-selects BOGOTÁ, D.C. when cities include it and no city is selected yet', () => {
      citiesReturn = {
        cities: [
          { id: 3, city_name: 'MEDELLÍN' },
          { id: 1, city_name: 'BOGOTÁ, D.C.' },
        ],
        isLoading: false,
        error: null,
      }
      facilitiesReturn = {
        facilities: [],
        isLoading: true,
        error: null,
      }

      const { container } = renderPage()

      const citySelect = container.querySelector('#city-filter') as HTMLSelectElement
      expect(citySelect.value).toBe('1')
    })

    it('does not auto-select city when the default name does not appear in results', () => {
      citiesReturn = {
        cities: [{ id: 3, city_name: 'MEDELLÍN' }],
        isLoading: false,
        error: null,
      }

      const { container } = renderPage()

      const citySelect = container.querySelector('#city-filter') as HTMLSelectElement
      expect(citySelect.value).toBe('')
    })

    it('auto-selects C.C Parque La Colina once the city is set and its facilities load', () => {
      citiesReturn = {
        cities: [{ id: 1, city_name: 'BOGOTÁ, D.C.' }],
        isLoading: false,
        error: null,
      }
      facilitiesReturn = {
        facilities: [
          { id: 5, display_name: 'C.C Unicentro', city_id: 1 },
          { id: 9, display_name: 'C.C Parque La Colina', city_id: 1 },
        ],
        isLoading: false,
        error: null,
      }

      const { container } = renderPage()

      const facilitySelect = container.querySelector('#facility-filter') as HTMLSelectElement
      expect(facilitySelect.value).toBe('9')
    })
  })

  describe('class-type filter', () => {
    it('shows only All option when no class types are available', () => {
      const { container } = renderPage()

      const classTypeSelect = container.querySelector('#class-type-filter') as HTMLSelectElement
      const options = classTypeSelect.querySelectorAll('option')
      expect(options).toHaveLength(1)
      expect(options[0].textContent).toMatch(/Todas|All/)
    })

    it('is disabled when no class types are available', () => {
      const { container } = renderPage()

      const classTypeSelect = container.querySelector('#class-type-filter') as HTMLSelectElement
      expect(classTypeSelect).toBeDisabled()
    })

    it('renders class type options from schedule response', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      const { container } = renderPage()

      const classTypeSelect = container.querySelector('#class-type-filter') as HTMLSelectElement
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

      const { container } = renderPage()

      const classTypeSelect = container.querySelector('#class-type-filter') as HTMLSelectElement
      expect(classTypeSelect).not.toBeDisabled()
    })

    it('filters sessions when a class type is selected', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      const user = userEvent.setup()
      const { container } = renderPage()

      const sessionList = screen.getByRole('list')
      expect(within(sessionList).getByText('Yoga')).toBeInTheDocument()
      expect(within(sessionList).getByText('Spinning')).toBeInTheDocument()

      const classTypeSelect = container.querySelector('#class-type-filter') as HTMLSelectElement
      await user.selectOptions(classTypeSelect, '10')

      await waitFor(() => {
        expect(within(sessionList).getByText('Yoga')).toBeInTheDocument()
      })
      expect(within(sessionList).queryByText('Spinning')).not.toBeInTheDocument()
    })
  })

  describe('class color accent', () => {
    function getCards(): HTMLElement[] {
      const list = screen.getByRole('list')
      return Array.from(list.querySelectorAll('li'))
    }

    it('applies a deterministic pastel left border color to each session card', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const cards = getCards()
      expect(cards).toHaveLength(2)

      const firstBorder = cards[0].style.borderLeftColor
      const secondBorder = cards[1].style.borderLeftColor

      expect(firstBorder).toBeTruthy()
      expect(secondBorder).toBeTruthy()
    })

    it('assigns the same color to sessions with the same class name', () => {
      const sessions: Session[] = [
        { id: '1', facilityId: 9, activityName: 'Yoga', activityId: 10, startsAt: '2026-07-18T12:00:00.000Z' },
        { id: '2', facilityId: 9, activityName: 'Yoga', activityId: 10, startsAt: '2026-07-18T14:00:00.000Z' },
      ]
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const cards = getCards()
      expect(cards).toHaveLength(2)

      expect(cards[0].style.borderLeftColor).toBe(cards[1].style.borderLeftColor)
    })

    it('assigns different colors to sessions with different class names', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const cards = getCards()
      expect(cards).toHaveLength(2)

      expect(cards[0].style.borderLeftColor).not.toBe(cards[1].style.borderLeftColor)
    })
  })

  describe('booking state', () => {
    function getAllDots(
      list: HTMLElement,
      name: string,
    ) {
      return within(list).getAllByLabelText(name)
    }

    function getActiveDot(list: HTMLElement, name: string) {
      const dots = within(list).getAllByLabelText(name)
      const active = dots.find((d) => d.getAttribute('aria-current') === 'true')
      if (!active) throw new Error(`No active dot found for label "${name}"`)
      return active
    }

    function assertAllInactive(list: HTMLElement) {
      ;(['Pending', 'Booked', 'Failed'] as const).forEach((label) => {
        getAllDots(list, label).forEach((dot) => {
          expect(dot).not.toHaveAttribute('aria-current')
        })
      })
    }

    function getCard(list: HTMLElement, name: string) {
      return within(list).getByRole('button', { name })
    }

    it('renders all three dots inactive with cards as tappable buttons', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const sessionList = screen.getByRole('list')

      assertAllInactive(sessionList)
      expect(getAllDots(sessionList, 'Pending')).toHaveLength(2)
      expect(getAllDots(sessionList, 'Booked')).toHaveLength(2)
      expect(getAllDots(sessionList, 'Failed')).toHaveLength(2)

      // Cards are now buttons themselves (no separate Reserve button)
      expect(getCard(sessionList, 'Yoga')).toBeInTheDocument()
      expect(getCard(sessionList, 'Spinning')).toBeInTheDocument()
    })

    it('calls useBookingRequest.create when an unreserved card is tapped', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const yogaCard = getCard(sessionList, 'Yoga')
      await user.click(yogaCard)

      expect(bookingReturn.create).toHaveBeenCalledWith(1)
    })

    it('renders pending state with amber clock dot lit', () => {
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

      const pendingDot = getActiveDot(sessionList, 'Pending')
      expect(pendingDot).toHaveClass('bg-amber-500')

      const pendingDots = getAllDots(sessionList, 'Pending')
      expect(pendingDots).toHaveLength(2)
      const [activePending, inactivePending] = pendingDots
      expect(activePending).toHaveAttribute('aria-current', 'true')
      expect(inactivePending).not.toHaveAttribute('aria-current')

      expect(getAllDots(sessionList, 'Booked')).toHaveLength(2)
      expect(getAllDots(sessionList, 'Failed')).toHaveLength(2)

      // No reserve buttons — the second card is just tappable, not a labelled button with "Reserve"
      expect(
        within(sessionList).queryByRole('button', { name: /Reservar|Reserve/ })
      ).not.toBeInTheDocument()
    })

    it('renders booked state with green check dot lit', () => {
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

      const bookedDot = getActiveDot(sessionList, 'Booked')
      expect(bookedDot).toHaveClass('bg-emerald-500')

      expect(getAllDots(sessionList, 'Pending')).toHaveLength(2)
      expect(getAllDots(sessionList, 'Booked')).toHaveLength(2)
      expect(getAllDots(sessionList, 'Failed')).toHaveLength(2)

      // No reserve button — the second card is a tappable button with the session name
      expect(
        within(sessionList).queryByRole('button', { name: /Reservar|Reserve/ })
      ).not.toBeInTheDocument()
      expect(getCard(sessionList, 'Spinning')).toBeInTheDocument()
    })

    it('renders failed state with red X dot lit', () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_FAILED },
        ],
        classTypes: MOCK_CLASS_TYPES,
      }

      renderPage()

      const sessionList = screen.getByRole('list')

      const failedDot = getActiveDot(sessionList, 'Failed')
      expect(failedDot).toHaveClass('bg-red-500')

      // Failed card should NOT be a tappable button (no role="button")
      const listItems = sessionList.querySelectorAll('li')
      expect(listItems[0]).not.toHaveAttribute('role', 'button')
    })

    it('dims the card during loading after tap', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: true,
        error: null,
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const yogaCard = getCard(sessionList, 'Yoga')
      await user.click(yogaCard)

      expect(yogaCard.style.opacity).toBe('0.5')
      // Second card should not be dimmed
      const spinningCard = getCard(sessionList, 'Spinning')
      expect(spinningCard.style.opacity).toBe('1')
    })

    it('shows error and Retry button on the targeted row after failed create', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: MOCK_SESSIONS,
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: false,
        error: 'Schedule entry is in the past.',
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const yogaCard = getCard(sessionList, 'Yoga')
      await user.click(yogaCard)

      assertAllInactive(sessionList)

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
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: false,
        error: null,
        bookingRequest: MOCK_BOOKING_PENDING,
      }

      renderPage()

      const sessionList = screen.getByRole('list')

      // No reserve button — the second card is tappable only
      expect(
        within(sessionList).queryByRole('button', { name: /Reservar|Reserve/ })
      ).not.toBeInTheDocument()
    })

    it('calls cancel when a pending card is tapped', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_PENDING },
        ],
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: false,
        error: null,
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const yogaCard = getCard(sessionList, 'Yoga')
      await user.click(yogaCard)

      expect(bookingReturn.cancel).toHaveBeenCalledWith(MOCK_BOOKING_PENDING.id)
    })

    it('shows confirmation dialog when a booked card is tapped', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_BOOKED },
        ],
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: false,
        error: null,
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const yogaCard = getCard(sessionList, 'Yoga')
      await user.click(yogaCard)

      // Confirmation dialog should appear
      expect(screen.getByText(/Cancel reservation\?|¿Cancelar reserva?/)).toBeInTheDocument()
      expect(bookingReturn.cancel).not.toHaveBeenCalled()

      // Dismiss dialog
      const noButton = screen.getByRole('button', { name: 'No' })
      await user.click(noButton)
      expect(screen.queryByText(/Cancel reservation\?|¿Cancelar reserva?/)).not.toBeInTheDocument()
    })

    it('confirms cancel when confirm button is clicked on dialog', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_BOOKED },
        ],
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: false,
        error: null,
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      const sessionList = screen.getByRole('list')
      const yogaCard = getCard(sessionList, 'Yoga')
      await user.click(yogaCard)

      const retryButton = screen.getByRole('button', { name: /Reintentar|Retry/ })
      await user.click(retryButton)

      expect(bookingReturn.cancel).toHaveBeenCalledWith(MOCK_BOOKING_BOOKED.id)
      expect(screen.queryByText(/Cancel reservation\?|¿Cancelar reserva?/)).not.toBeInTheDocument()
    })

    it('does nothing when a failed card is tapped', async () => {
      scheduleReturn = {
        ...DEFAULT_SCHEDULE_RESULT,
        sessions: [
          { ...MOCK_SESSIONS[0], bookingRequest: MOCK_BOOKING_FAILED },
        ],
        classTypes: MOCK_CLASS_TYPES,
      }
      bookingReturn = {
        create: vi.fn().mockResolvedValue(undefined),
        cancel: vi.fn().mockResolvedValue(true),
        isLoading: false,
        error: null,
        bookingRequest: null,
      }

      const user = userEvent.setup()
      renderPage()

      // Failed card is not a button, so getByRole('button', {name: 'Yoga'}) will not find it
      const listItems = screen.getAllByRole('listitem')
      await user.click(listItems[0])

      expect(bookingReturn.create).not.toHaveBeenCalled()
      expect(bookingReturn.cancel).not.toHaveBeenCalled()
    })
  })
})
