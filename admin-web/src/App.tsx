import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AuthProvider } from './context/AuthContext'
import { BookingsPage } from './pages/BookingsPage'
import { CategoriesPage } from './pages/CategoriesPage'
import { DashboardPage } from './pages/DashboardPage'
import { LoginPage } from './pages/LoginPage'
import { MfaChallengePage } from './pages/MfaChallengePage'
import { MfaSetupPage } from './pages/MfaSetupPage'
import { ProvidersPage } from './pages/ProvidersPage'
import { ServicesPage } from './pages/ServicesPage'
import { SubscriptionsPage } from './pages/SubscriptionsPage'
import { UsersPage } from './pages/UsersPage'

export function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/mfa-setup" element={<MfaSetupPage />} />
          <Route path="/mfa-challenge" element={<MfaChallengePage />} />
          <Route
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route path="/" element={<DashboardPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/providers" element={<ProvidersPage />} />
            <Route path="/subscriptions" element={<SubscriptionsPage />} />
            <Route path="/categories" element={<CategoriesPage />} />
            <Route path="/services" element={<ServicesPage />} />
            <Route path="/bookings" element={<BookingsPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
