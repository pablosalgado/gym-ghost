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
    })
  })

  describe('pending status', () => {
    it('lights the pending dot amber, others gray', () => {
      render(<BookingStatusBadge status="pending" />)

      expect(activeDot('Pending')).toHaveClass('bg-amber-500')
      expect(inactiveDot('Booked')).toHaveClass('bg-gray-200')
      expect(inactiveDot('Failed')).toHaveClass('bg-gray-200')
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
  })
})
