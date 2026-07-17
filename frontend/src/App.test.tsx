import { render, screen } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import App from './App'

describe('App', () => {
  it('renders the greeting message', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ message: 'Hello from Gym Ghost' }),
    }))

    render(<App />)

    expect(screen.getByText('Loading greeting...')).toBeInTheDocument()
    expect(await screen.findByText('Hello from Gym Ghost')).toBeInTheDocument()
  })
})
