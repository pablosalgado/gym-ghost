import { useTranslation } from 'react-i18next'
import { useAuth } from './hooks/useAuth'
import LoginPage from './components/LoginPage'

export default function App() {
  const { isAuthenticated, logout, login, isLoading, error } = useAuth()
  const { t } = useTranslation()

  if (!isAuthenticated) {
    return <LoginPage login={login} isLoading={isLoading} error={error} />
  }

  return (
    <div className="min-h-dvh flex flex-col items-center justify-center gap-4">
      <h1 className="text-3xl font-bold">
        {t('app.title')}
      </h1>
      <button
        onClick={logout}
        className="min-h-11 rounded bg-gray-200 px-4 py-2 hover:bg-gray-300"
      >
        {t('auth.logOut')}
      </button>
    </div>
  )
}
