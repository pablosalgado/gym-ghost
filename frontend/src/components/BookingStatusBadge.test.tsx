import { render, screen } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import BookingStatusBadge from './BookingStatusBadge'

describe('BookingStatusBadge', () => {
  describe('available status', () => {
    it('renders a gray badge with Available label', () => {
      render(<BookingStatusBadge status="available" />)

      const badge = screen.getByLabelText('Available')
      expect(badge).toBeInTheDocument()
      expect(badge).toHaveClass('bg-gray-300')
    })

    it('renders no text or buttons', () => {
      render(<BookingStatusBadge status="available" />)

      const badge = screen.getByLabelText('Available')
      expect(screen.queryByRole('button')).not.toBeInTheDocument()
      expect(badge.parentElement?.textContent).toBe('')
    })
  })

  describe('pending status', () => {
    it('renders an amber badge with Pending label', () => {
      render(<BookingStatusBadge status="pending" />)

      const badge = screen.getByLabelText('Pending')
      expect(badge).toBeInTheDocument()
      expect(badge).toHaveClass('bg-amber-500')
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

      const badge = screen.getByLabelText('Pending')
      const container = badge.parentElement!
      expect(container.textContent).toBe('')
    })
  })

  describe('booked status', () => {
    it('renders a green badge with Booked label', () => {
      render(<BookingStatusBadge status="booked" />)

      const badge = screen.getByLabelText('Booked')
      expect(badge).toBeInTheDocument()
      expect(badge).toHaveClass('bg-emerald-500')
    })
  })

  describe('failed status', () => {
    it('renders a red badge with Failed label', () => {
      render(<BookingStatusBadge status="failed" />)

      const badge = screen.getByLabelText('Failed')
      expect(badge).toBeInTheDocument()
      expect(badge).toHaveClass('bg-red-500')
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
