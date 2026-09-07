import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/auth-context'

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { session, isAdmin, loading, mfaStatus } = useAuth()

  if (loading || (session && mfaStatus === 'checking')) {
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

  // Spec section 43 / SECURITY.md: MFA is required for admin accounts, not
  // optional. signInWithPassword alone only gets to aal1 - a verified
  // factor still needs a per-session challenge, and no factor at all means
  // enrollment isn't done yet. Neither state gets past here.
  if (mfaStatus === 'enroll') return <Navigate to="/mfa-setup" replace />
  if (mfaStatus === 'challenge') return <Navigate to="/mfa-challenge" replace />

  return <>{children}</>
}
