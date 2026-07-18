import { Link, Outlet, useNavigate } from 'react-router'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../hooks/useAuth'
import LanguageSwitcher from './LanguageSwitcher'
import MobileMenu from './MobileMenu'

export default function AppShell() {
  const { logout } = useAuth()
  const { t } = useTranslation()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-dvh flex flex-col">
      <header className="relative flex flex-wrap items-center justify-between gap-x-4 gap-y-2 border-b border-gray-200 px-3 py-2 sm:px-4 sm:py-3">
        <Link to="/" className="text-lg font-bold">
          Gym Ghost
        </Link>
        <div className="flex items-center gap-3 sm:gap-4">
          <div className="hidden sm:flex sm:items-center sm:gap-4">
            <LanguageSwitcher />
            <button
              onClick={handleLogout}
              className="min-h-11 rounded bg-gray-200 px-4 py-2 hover:bg-gray-300"
            >
              {t('auth.logOut')}
            </button>
          </div>
          <MobileMenu />
        </div>
      </header>
      <main className="flex-1">
        <Outlet />
      </main>
    </div>
  )
}
