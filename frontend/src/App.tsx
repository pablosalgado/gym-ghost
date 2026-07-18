import { Navigate, Route, Routes } from 'react-router'
import LoginPage from './components/LoginPage'
import RequireAuth from './components/RequireAuth'
import AppShell from './components/AppShell'
import LandingPage from './pages/LandingPage'
import SchedulePlaceholderPage from './pages/SchedulePlaceholderPage'

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<RequireAuth />}>
        <Route element={<AppShell />}>
          <Route path="/" element={<LandingPage />} />
          <Route path="/schedule" element={<SchedulePlaceholderPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
