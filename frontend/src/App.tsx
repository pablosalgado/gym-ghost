import { Navigate, Route, Routes } from 'react-router'
import LoginPage from './components/LoginPage'
import RequireAuth from './components/RequireAuth'
import AppShell from './components/AppShell'
import LandingPage from './pages/LandingPage'
import SchedulePage from './pages/SchedulePage'
import CreateGymMemberPage from './pages/CreateGymMemberPage'

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<RequireAuth />}>
        <Route element={<AppShell />}>
          <Route path="/" element={<LandingPage />} />
          <Route path="/schedule" element={<SchedulePage />} />
          <Route path="/gym-members/new" element={<CreateGymMemberPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
