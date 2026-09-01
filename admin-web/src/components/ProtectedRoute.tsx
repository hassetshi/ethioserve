import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/auth-context'

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { session, isAdmin, loading } = useAuth()

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center text-gray-500">Loading...</div>
    )
  }

  if (!session) return <Navigate to="/login" replace />

  if (!isAdmin) {
    return (
      <div className="flex h-screen flex-col items-center justify-center gap-2 text-center">
        <p className="text-lg font-medium">This account is not an administrator.</p>
        <p className="text-gray-500">Sign in with an admin account to continue.</p>
      </div>
    )
  }

  return <>{children}</>
}
