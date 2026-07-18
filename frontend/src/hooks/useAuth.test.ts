import { act, renderHook } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AUTH_TOKEN_STORAGE_KEY, useAuth } from './useAuth'

describe('useAuth', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it('stores token when login succeeds', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ token: 'token-123' }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const { result } = renderHook(() => useAuth())

    await act(async () => {
      const loginSucceeded = await result.current.login(
        'member@example.com',
        'secret'
      )
      expect(loginSucceeded).toBe(true)
    })

    expect(fetchMock).toHaveBeenCalledWith('/api/v1/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'member@example.com',
        password: 'secret',
      }),
    })
    expect(result.current.token).toBe('token-123')
    expect(result.current.isAuthenticated).toBe(true)
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBe('token-123')
    expect(result.current.error).toBeNull()
  })

  it('sets an error when login fails', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        json: () =>
          Promise.resolve({
            errors: [{ detail: 'Invalid credentials' }],
          }),
      })
    )

    const { result } = renderHook(() => useAuth())

    await act(async () => {
      const loginSucceeded = await result.current.login(
        'member@example.com',
        'wrong-password'
      )
      expect(loginSucceeded).toBe(false)
    })

    expect(result.current.token).toBeNull()
    expect(result.current.isAuthenticated).toBe(false)
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBeNull()
    expect(result.current.error).toEqual({
      kind: 'server',
      detail: 'Invalid credentials',
    })
  })

  it('sets a key error when the failure payload has no server detail', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        json: () => Promise.resolve({}),
      })
    )

    const { result } = renderHook(() => useAuth())

    await act(async () => {
      await result.current.login('member@example.com', 'wrong-password')
    })

    expect(result.current.error).toEqual({
      kind: 'key',
      key: 'auth.invalidCredentials',
    })
  })

  it('sets a key error when the success response is malformed', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ unexpected: true }),
      })
    )

    const { result } = renderHook(() => useAuth())

    await act(async () => {
      await result.current.login('member@example.com', 'secret')
    })

    expect(result.current.error).toEqual({
      kind: 'key',
      key: 'auth.invalidAuthResponse',
    })
  })

  it('sets a key error when the request fails to reach the server', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockRejectedValue(new Error('network down'))
    )

    const { result } = renderHook(() => useAuth())

    await act(async () => {
      await result.current.login('member@example.com', 'secret')
    })

    expect(result.current.error).toEqual({
      kind: 'key',
      key: 'auth.loginUnavailable',
    })
  })

  it('clears token and state on logout', () => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, 'saved-token')

    const { result } = renderHook(() => useAuth())

    expect(result.current.isAuthenticated).toBe(true)
    expect(result.current.token).toBe('saved-token')

    act(() => {
      result.current.logout()
    })

    expect(result.current.token).toBeNull()
    expect(result.current.isAuthenticated).toBe(false)
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBeNull()
  })
})
