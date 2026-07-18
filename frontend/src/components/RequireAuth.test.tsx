import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RequireAuth from './RequireAuth'
import { useAuth, type UseAuthResult } from '../hooks/useAuth'

vi.mock('../hooks/useAuth', () => ({
  useAuth: vi.fn(),
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

function LoginProbe() {
  const location = useLocation()
  const from = (
    location.state as { from?: { pathname?: string } } | null
  )?.from?.pathname
  return <div>login page{from ? ` (from ${from})` : ''}</div>
}

function renderAt(initialPath: string) {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <Routes>
        <Route path="/login" element={<LoginProbe />} />
        <Route element={<RequireAuth />}>
          <Route path="/schedule" element={<div>secret content</div>} />
        </Route>
      </Routes>
    </MemoryRouter>
  )
}

describe('RequireAuth', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('redirects unauthenticated users to /login, remembering the target', () => {
    mockedUseAuth.mockReturnValue(buildUseAuthMock())

    renderAt('/schedule')

    expect(
      screen.getByText('login page (from /schedule)')
    ).toBeInTheDocument()
    expect(screen.queryByText('secret content')).not.toBeInTheDocument()
  })

  it('renders protected content for authenticated users', () => {
    mockedUseAuth.mockReturnValue(
      buildUseAuthMock({ isAuthenticated: true, token: 'test-token' })
    )

    renderAt('/schedule')

    expect(screen.getByText('secret content')).toBeInTheDocument()
    expect(screen.queryByText(/login page/)).not.toBeInTheDocument()
  })
})
