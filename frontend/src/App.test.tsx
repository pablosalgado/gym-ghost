import { render, screen, fireEvent } from '@testing-library/react'
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

  it('renders app title and logout button when authenticated', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    render(<App />)

    expect(screen.getByRole('heading', { name: /gym ghost/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Cerrar sesión' })).toBeInTheDocument()
  })

  it('uses a full-height shell that works with body safe-area padding', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    const { container } = render(<App />)

    expect(container.firstChild).toHaveClass('min-h-dvh')
  })

  it('calls logout when logout button is clicked', () => {
    const logoutMock = vi.fn()
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token', logout: logoutMock })
    )

    render(<App />)

    fireEvent.click(screen.getByRole('button', { name: 'Cerrar sesión' }))

    expect(logoutMock).toHaveBeenCalled()
  })

  it('applies a 44px minimum touch target to the logout button', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    render(<App />)

    const logoutButton = screen.getByRole('button', { name: 'Cerrar sesión' })

    expect(logoutButton).toHaveClass('min-h-11')
  })
})
