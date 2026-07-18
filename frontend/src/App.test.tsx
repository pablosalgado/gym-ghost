import { render, screen, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
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

function renderApp(initialPath = '/') {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <App />
    </MemoryRouter>
  )
}

describe('App', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('redirects unauthenticated visitors to the login page', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock({ isAuthenticated: false }))

    renderApp()

    expect(screen.getByTestId('login-page')).toBeInTheDocument()
  })

  it('redirects unknown paths to /', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock({ isAuthenticated: false }))

    renderApp('/no-such-page')

    expect(screen.getByTestId('login-page')).toBeInTheDocument()
  })

  it('renders the landing page inside the shell when authenticated', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    renderApp()

    expect(
      screen.getByRole('heading', { name: 'Bienvenido a Gym Ghost' })
    ).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Gym Ghost' })).toBeInTheDocument()
    expect(screen.getByRole('combobox')).toBeInTheDocument()
    expect(
      screen.getByRole('button', { name: 'Cerrar sesión' })
    ).toBeInTheDocument()
  })

  it('uses a full-height shell that works with body safe-area padding', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    const { container } = renderApp()

    expect(container.firstChild).toHaveClass('min-h-dvh')
  })

  it('navigates from the landing CTA to the schedule placeholder', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    renderApp()

    fireEvent.click(screen.getByText('Explorar el horario'))

    expect(
      screen.getByText('Próximamente: el horario de clases.')
    ).toBeInTheDocument()
  })

  it('calls logout and returns to /login from the shell button', () => {
    const logoutMock = vi.fn()
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token', logout: logoutMock })
    )

    renderApp()

    fireEvent.click(screen.getByRole('button', { name: 'Cerrar sesión' }))

    expect(logoutMock).toHaveBeenCalled()
    expect(screen.getByTestId('login-page')).toBeInTheDocument()
  })

  it('applies a 44px minimum touch target to the logout button', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    renderApp()

    expect(
      screen.getByRole('button', { name: 'Cerrar sesión' })
    ).toHaveClass('min-h-11')
  })
})
