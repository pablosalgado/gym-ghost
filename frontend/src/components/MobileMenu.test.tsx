import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MobileMenu from './MobileMenu'
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

function renderMobileMenu() {
  return render(
    <MemoryRouter>
      <MobileMenu />
    </MemoryRouter>
  )
}

describe('MobileMenu', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders hamburger button with correct accessibility attributes', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    const button = screen.getByRole('button', {
      name: 'Abrir menú de navegación',
    })
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('aria-expanded', 'false')
    expect(button).toHaveAttribute('aria-controls', 'mobile-menu')
  })

  it('does not render menu when closed', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
    expect(screen.queryByRole('menuitem')).not.toBeInTheDocument()
  })

  it('opens menu when hamburger is clicked', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    const button = screen.getByRole('button', {
      name: 'Abrir menú de navegación',
    })
    fireEvent.click(button)

    expect(button).toHaveAttribute('aria-expanded', 'true')
    expect(screen.getByRole('menu')).toBeInTheDocument()
    expect(screen.getByRole('menuitem', { name: 'Cerrar sesión' })).toBeInTheDocument()
  })

  it('closes menu when hamburger is clicked again', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    const button = screen.getByRole('button', {
      name: 'Abrir menú de navegación',
    })
    fireEvent.click(button)
    expect(screen.getByRole('menu')).toBeInTheDocument()

    fireEvent.click(button)
    expect(button).toHaveAttribute('aria-expanded', 'false')
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('closes menu when Escape key is pressed', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    const button = screen.getByRole('button', {
      name: 'Abrir menú de navegación',
    })
    fireEvent.click(button)
    expect(screen.getByRole('menu')).toBeInTheDocument()

    fireEvent.keyDown(document, { key: 'Escape' })
    expect(button).toHaveAttribute('aria-expanded', 'false')
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('closes menu when clicking outside', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    const button = screen.getByRole('button', {
      name: 'Abrir menú de navegación',
    })
    fireEvent.click(button)
    expect(screen.getByRole('menu')).toBeInTheDocument()

    fireEvent.mouseDown(document.body)
    expect(button).toHaveAttribute('aria-expanded', 'false')
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('renders language switcher in menu', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderMobileMenu()

    fireEvent.click(
      screen.getByRole('button', { name: 'Abrir menú de navegación' })
    )

    expect(screen.getByRole('combobox', { name: /idioma/i })).toBeInTheDocument()
  })

  it('calls logout and navigates to /login when logout is clicked', () => {
    const logoutMock = vi.fn()
    mockedUseAuth.mockReturnValue(buildUseAuthMock({ logout: logoutMock }))

    renderMobileMenu()

    fireEvent.click(
      screen.getByRole('button', { name: 'Abrir menú de navegación' })
    )
    fireEvent.click(screen.getByRole('menuitem', { name: 'Cerrar sesión' }))

    expect(logoutMock).toHaveBeenCalled()
  })
})
