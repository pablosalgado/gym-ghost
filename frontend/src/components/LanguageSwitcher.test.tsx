import { beforeEach, describe, expect, it } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { useTranslation } from 'react-i18next'
import i18n, { LANGUAGE_STORAGE_KEY } from '../i18n/i18n'
import LanguageSwitcher from './LanguageSwitcher'

function TranslatedProbe() {
  const { t } = useTranslation()
  return <p>{t('auth.logOut')}</p>
}

describe('LanguageSwitcher', () => {
  beforeEach(async () => {
    localStorage.clear()
    await i18n.changeLanguage('es-CO')
  })

  it('renders both language options with the active language selected', () => {
    render(<LanguageSwitcher />)

    const select = screen.getByRole('combobox', { name: /idioma/i })
    expect(select).toHaveValue('es-CO')
    expect(
      screen.getByRole('option', { name: 'Español (Colombia)' })
    ).toBeInTheDocument()
    expect(
      screen.getByRole('option', { name: 'English (US)' })
    ).toBeInTheDocument()
  })

  it('switches language, re-renders translations, and persists the choice', async () => {
    render(
      <>
        <LanguageSwitcher />
        <TranslatedProbe />
      </>
    )

    expect(screen.getByText('Cerrar sesión')).toBeInTheDocument()

    fireEvent.change(screen.getByRole('combobox'), {
      target: { value: 'en-US' },
    })

    expect(await screen.findByText('Log out')).toBeInTheDocument()
    expect(localStorage.getItem(LANGUAGE_STORAGE_KEY)).toBe('en-US')
    expect(document.documentElement.lang).toBe('en-US')
  })
})
