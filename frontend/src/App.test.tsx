import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import App from './App'
import { useAuth, type UseAuthResult } from './hooks/useAuth'

vi.mock('./hooks/useAuth', () => ({
  useAuth: vi.fn(),
}))

vi.mock('./components/LoginPage', () => ({
  default: () => <div data-testid="login-page">Login Page</div>,
}))

const mockedUseAuth = vi.mocked(useAuth)

function buildUseAuthMock(overrides: Partial<UseAuthResult> = {}): UseAuthResult {
  return {
    token: null,
    isAuthenticated: false,
    login: vi.fn().mockResolvedValue(true),
    logout: vi.fn(),
    isLoading: false,
    error: null,
    ...overrides,
  }
}

describe('App', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders LoginPage when not authenticated', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock({ isAuthenticated: false }))

    render(<App />)

    expect(screen.getByTestId('login-page')).toBeInTheDocument()
  })

  it('renders greeting when authenticated', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ message: 'Hello from Gym Ghost' }),
    }))
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    render(<App />)

    expect(await screen.findByText('Hello from Gym Ghost')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Log out' })).toBeInTheDocument()
  })

  it('uses a full-height shell that works with body safe-area padding', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ message: 'Hello from Gym Ghost' }),
    }))
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    const { container } = render(<App />)

    await screen.findByText('Hello from Gym Ghost')
    expect(container.firstChild).toHaveClass('min-h-dvh')
  })

  it('fetches greeting with Authorization header when authenticated', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ message: 'Hello from Gym Ghost' }),
    })
    vi.stubGlobal('fetch', fetchMock)
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    render(<App />)

    await screen.findByText('Hello from Gym Ghost')
    expect(fetchMock).toHaveBeenCalledWith(
      '/api/v1/hello',
      expect.objectContaining({
        headers: expect.objectContaining({ Authorization: 'Bearer test-token' }),
      })
    )
  })

  it('calls logout when logout button is clicked', async () => {
    const logoutMock = vi.fn()
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ message: 'Hello' }),
    }))
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token', logout: logoutMock })
    )

    render(<App />)

    await screen.findByText('Hello')
    fireEvent.click(screen.getByRole('button', { name: 'Log out' }))

    expect(logoutMock).toHaveBeenCalled()
  })

  it('applies a 44px minimum touch target to the logout button', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ message: 'Hello' }),
    }))
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    render(<App />)

    const logoutButton = await screen.findByRole('button', { name: 'Log out' })

    expect(logoutButton).toHaveClass('min-h-11')
  })

  it('calls logout on 401 response', async () => {
    const logoutMock = vi.fn()
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
    }))
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'expired-token', logout: logoutMock })
    )

    render(<App />)

    await waitFor(() => {
      expect(logoutMock).toHaveBeenCalled()
    })
  })
})
