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

    expect(screen.getByRole('heading', { name: 'Log in' })).toBeInTheDocument()
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
    expect(
      screen.getByRole('button', {
        name: 'Log in',
      })
    ).toBeInTheDocument()
    expect(container.firstChild).toHaveClass('min-h-full')
  })

  it('applies a 44px minimum touch target to the form controls', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    render(<LoginPage />)

    expect(screen.getByLabelText('Email')).toHaveClass('min-h-11')
    expect(screen.getByLabelText('Password')).toHaveClass('min-h-11')
    expect(screen.getByRole('button', { name: 'Log in' })).toHaveClass('min-h-11')
  })

  it('shows an error message for invalid credentials', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({
        error: 'Invalid credentials',
      })
    )

    render(<LoginPage />)

    expect(screen.getByRole('alert')).toHaveTextContent('Invalid credentials')
  })

  it('calls login on submit', async () => {
    const loginMock = vi.fn().mockResolvedValue(true)
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({
        login: loginMock,
      })
    )

    render(<LoginPage />)

    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'member@example.com' },
    })
    fireEvent.change(screen.getByLabelText('Password'), {
      target: { value: 'secret' },
    })
    fireEvent.click(
      screen.getByRole('button', {
        name: 'Log in',
      })
    )

    await waitFor(() => {
      expect(loginMock).toHaveBeenCalledWith('member@example.com', 'secret')
    })
  })
})
