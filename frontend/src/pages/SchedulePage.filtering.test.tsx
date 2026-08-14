import { render, screen, waitFor, within } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import { MemoryRouter } from 'react-router'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import SchedulePage from './SchedulePage'
import { AUTH_TOKEN_STORAGE_KEY } from '../hooks/useAuth'

const SCHEDULE_RESPONSE = {
  schedule: [
    {
      id: 1,
      activity_name: 'Yoga',
      activity_id: 10,
      facility_id: 9,
      starts_at: '2026-07-18T12:00:00.000Z',
    },
    {
      id: 2,
      activity_name: 'Spinning',
      activity_id: 20,
      facility_id: 9,
      starts_at: '2026-07-18T14:00:00.000Z',
    },
  ],
  class_types: [
    { id: 10, name: 'Yoga' },
    { id: 20, name: 'Spinning' },
  ],
}

const fetchMock = vi.fn()

vi.mock('../hooks/useCities', () => ({
  useCities: () => ({
    cities: [{ id: 1, city_name: 'BOGOTÁ, D.C.' }],
    isLoading: false,
    error: null,
  }),
}))

vi.mock('../hooks/useFacilities', () => ({
  useFacilities: () => ({
    facilities: [{ id: 9, display_name: 'C.C Parque La Colina', city_id: 1 }],
    isLoading: false,
    error: null,
  }),
}))

vi.mock('../hooks/useBookingRequest', () => ({
  useBookingRequest: () => ({
    create: vi.fn().mockResolvedValue(undefined),
    cancel: vi.fn().mockResolvedValue(true),
    isLoading: false,
    error: null,
    bookingRequest: null,
  }),
}))

function renderPage() {
  return render(
    <MemoryRouter>
      <SchedulePage />
    </MemoryRouter>,
  )
}

describe('SchedulePage class filtering', () => {
  beforeEach(() => {
    vi.setSystemTime(new Date('2026-07-18T02:30:00.000Z'))
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, 'test-token')
    fetchMock.mockReset()
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve(SCHEDULE_RESPONSE),
    })
    vi.stubGlobal('fetch', fetchMock)
  })

  afterEach(() => {
    localStorage.clear()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('filters loaded sessions without issuing another schedule request', async () => {
    const user = userEvent.setup()
    renderPage()

    const sessionList = await waitFor(() => screen.getByRole('list'))
    await waitFor(() => expect(within(sessionList).getByText('Yoga')).toBeInTheDocument())
    const classTypeSelect = screen.getByLabelText(/Clase|Class/)

    expect(fetchMock).toHaveBeenCalledTimes(1)

    await user.selectOptions(classTypeSelect, '10')

    await waitFor(() => {
      expect(within(sessionList).queryByText('Spinning')).not.toBeInTheDocument()
    })
    expect(within(sessionList).getByText('Yoga')).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(1)

    await user.selectOptions(classTypeSelect, '')

    expect(within(sessionList).getByText('Yoga')).toBeInTheDocument()
    expect(within(sessionList).getByText('Spinning')).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })
})
