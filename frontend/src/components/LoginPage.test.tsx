import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import LoginPage from './LoginPage'
import { useAuth, type UseAuthResult } from '../hooks/useAuth'

vi.mock('../hooks/useAuth', () => ({
  useAuth: vi.fn(),
}))

const mockedUseAuth = vi.mocked(useAuth)

function buildUseAuthMock(
  overrides: Partial<UseAuthResult> = {}
): UseAuthResult {
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

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the login form', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    const { container } = render(<LoginPage />)

    expect(
      screen.getByRole('heading', { name: 'Iniciar sesión' })
    ).toBeInTheDocument()
    expect(screen.getByLabelText('Correo electrónico')).toBeInTheDocument()
    expect(screen.getByLabelText('Contraseña')).toBeInTheDocument()
    expect(
      screen.getByRole('button', {
        name: 'Iniciar sesión',
      })
    ).toBeInTheDocument()
    expect(container.firstChild).toHaveClass('min-h-dvh')
  })

  it('applies a 44px minimum touch target to the form controls', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    render(<LoginPage />)

    expect(screen.getByLabelText('Correo electrónico')).toHaveClass('min-h-11')
    expect(screen.getByLabelText('Contraseña')).toHaveClass('min-h-11')
    expect(
      screen.getByRole('button', { name: 'Iniciar sesión' })
    ).toHaveClass('min-h-11')
  })

  it('shows a server-provided error message verbatim in any locale', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({
        error: { kind: 'server', detail: 'Invalid credentials' },
      })
    )

    render(<LoginPage />)

    expect(screen.getByRole('alert')).toHaveTextContent('Invalid credentials')
  })

  it('shows a translated error for client-side failures', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({
        error: { kind: 'key', key: 'auth.invalidCredentials' },
      })
    )

    render(<LoginPage />)

    expect(screen.getByRole('alert')).toHaveTextContent(
      'Correo o contraseña inválidos.'
    )
  })

  it('calls login on submit', async () => {
    const loginMock = vi.fn().mockResolvedValue(true)
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({
        login: loginMock,
      })
    )

    render(<LoginPage />)

    fireEvent.change(screen.getByLabelText('Correo electrónico'), {
      target: { value: 'member@example.com' },
    })
    fireEvent.change(screen.getByLabelText('Contraseña'), {
      target: { value: 'secret' },
    })
    fireEvent.click(
      screen.getByRole('button', {
        name: 'Iniciar sesión',
      })
    )

    await waitFor(() => {
      expect(loginMock).toHaveBeenCalledWith('member@example.com', 'secret')
    })
  })
})
