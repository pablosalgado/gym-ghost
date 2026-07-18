import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import AppShell from './AppShell'
import { useAuth, type UseAuthResult } from '../hooks/useAuth'

vi.mock('../hooks/useAuth', () => ({
  useAuth: vi.fn(),
}))

const mockedUseAuth = vi.mocked(useAuth)

function buildUseAuthMock(overrides: Partial<UseAuthResult> = {}): UseAuthResult {
  return {
    token: 'test-token',
    isAuthenticated: true,
    login: vi.fn(),
    logout: vi.fn(),
    isLoading: false,
    error: null,
    ...overrides,
  }
}

function renderShell() {
  return render(
    <MemoryRouter initialEntries={['/']}>
      <Routes>
        <Route element={<AppShell />}>
          <Route path="/" element={<div>page content</div>} />
        </Route>
        <Route path="/login" element={<div>login probe</div>} />
      </Routes>
    </MemoryRouter>
  )
}

describe('AppShell', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders brand, language switcher, logout, and the routed page', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderShell()

    expect(screen.getByRole('link', { name: 'Gym Ghost' })).toHaveAttribute(
      'href',
      '/'
    )
    expect(screen.getByRole('combobox')).toBeInTheDocument()
    expect(
      screen.getByRole('button', { name: 'Cerrar sesión' })
    ).toBeInTheDocument()
    expect(screen.getByText('page content')).toBeInTheDocument()
  })

  it('logs out and navigates to /login', () => {
    const logoutMock = vi.fn()
    mockedUseAuth.mockReturnValue(buildUseAuthMock({ logout: logoutMock }))

    renderShell()

    fireEvent.click(screen.getByRole('button', { name: 'Cerrar sesión' }))

    expect(logoutMock).toHaveBeenCalled()
    expect(screen.getByText('login probe')).toBeInTheDocument()
  })

  it('renders hamburger menu button', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderShell()

    expect(
      screen.getByRole('button', { name: 'Abrir menú de navegación' })
    ).toBeInTheDocument()
  })


})
