import { render, screen } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import BookingStatusBadge from './BookingStatusBadge'

function activeDot(name: string) {
  const dot = screen.getByLabelText(name)
  expect(dot).toHaveAttribute('aria-current', 'true')
  return dot
}

function inactiveDot(name: string) {
  const dot = screen.getByLabelText(name)
  expect(dot).not.toHaveAttribute('aria-current')
  return dot
}

describe('BookingStatusBadge', () => {
  describe('available status', () => {
    it('renders all three dots inactive', () => {
      render(<BookingStatusBadge status="available" />)

      expect(inactiveDot('Pending')).toHaveClass('bg-gray-200')
      expect(inactiveDot('Booked')).toHaveClass('bg-gray-200')
      expect(inactiveDot('Failed')).toHaveClass('bg-gray-200')
    })

    it('renders no text or buttons', () => {
      render(<BookingStatusBadge status="available" />)

      expect(screen.queryByRole('button')).not.toBeInTheDocument()
      expect(screen.getByLabelText('Pending').parentElement?.parentElement?.textContent).toBe('')
    })
  })

  describe('pending status', () => {
    it('lights the pending dot amber, others gray', () => {
      render(<BookingStatusBadge status="pending" />)

      expect(activeDot('Pending')).toHaveClass('bg-amber-500')
      expect(inactiveDot('Booked')).toHaveClass('bg-gray-200')
      expect(inactiveDot('Failed')).toHaveClass('bg-gray-200')
    })

    it('renders the pendingLabel text when provided', () => {
      render(
        <BookingStatusBadge
          status="pending"
          pendingLabel="Reservas a las 10:00"
        />
      )

      expect(screen.getByText('Reservas a las 10:00')).toBeInTheDocument()
    })

    it('does not render text when pendingLabel is omitted', () => {
      render(<BookingStatusBadge status="pending" />)

      expect(screen.queryByText(/./)).toBeNull()
    })
  })

  describe('booked status', () => {
    it('lights the booked dot green, others gray', () => {
      render(<BookingStatusBadge status="booked" />)

      expect(activeDot('Booked')).toHaveClass('bg-emerald-500')
      expect(inactiveDot('Pending')).toHaveClass('bg-gray-200')
      expect(inactiveDot('Failed')).toHaveClass('bg-gray-200')
    })
  })

  describe('failed status', () => {
    it('lights the failed dot red, others gray', () => {
      render(<BookingStatusBadge status="failed" />)

      expect(activeDot('Failed')).toHaveClass('bg-red-500')
      expect(inactiveDot('Pending')).toHaveClass('bg-gray-200')
      expect(inactiveDot('Booked')).toHaveClass('bg-gray-200')
    })

    it('renders retry button when onRetry is provided', () => {
      const onRetry = vi.fn()
      render(
        <BookingStatusBadge status="failed" onRetry={onRetry} retryLabel="Reintentar" />
      )

      const button = screen.getByRole('button', { name: 'Reintentar' })
      expect(button).toBeInTheDocument()

      button.click()
      expect(onRetry).toHaveBeenCalledOnce()
    })

    it('disables retry button when loading', () => {
      render(
        <BookingStatusBadge
          status="failed"
          onRetry={vi.fn()}
          isLoading={true}
          retryLabel="Reintentar"
        />
      )

      const button = screen.getByRole('button', { name: 'Reintentar' })
      expect(button).toBeDisabled()
    })

    it('does not render retry button when onRetry is omitted', () => {
      render(<BookingStatusBadge status="failed" />)

      expect(screen.queryByRole('button')).not.toBeInTheDocument()
    })

    it('uses default retryLabel "Retry" when not provided', () => {
      render(<BookingStatusBadge status="failed" onRetry={vi.fn()} />)

      expect(screen.getByRole('button', { name: 'Retry' })).toBeInTheDocument()
    })
  })
})
