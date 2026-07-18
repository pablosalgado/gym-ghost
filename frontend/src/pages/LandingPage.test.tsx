import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router'
import { describe, expect, it } from 'vitest'
import LandingPage from './LandingPage'

function renderLanding() {
  return render(
    <MemoryRouter initialEntries={['/']}>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/schedule" element={<div>schedule probe</div>} />
      </Routes>
    </MemoryRouter>
  )
}

describe('LandingPage', () => {
  it('renders the welcome copy and a schedule CTA', () => {
    renderLanding()

    expect(
      screen.getByRole('heading', { name: 'Bienvenido a Gym Ghost' })
    ).toBeInTheDocument()
    expect(
      screen.getByText('Tu compañero para reservar clases de gimnasio.')
    ).toBeInTheDocument()

    const cta = screen.getByRole('link')
    expect(cta).toHaveAttribute('href', '/schedule')
    expect(cta).toHaveTextContent('Explorar el horario')
  })

  it('navigates to /schedule from the CTA', () => {
    renderLanding()

    fireEvent.click(screen.getByRole('link'))

    expect(screen.getByText('schedule probe')).toBeInTheDocument()
  })
})
