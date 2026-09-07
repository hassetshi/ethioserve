import { useEffect, useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/auth-context'
import { supabase } from '../lib/supabase'

// Reached at aal1 with an already-verified TOTP factor (ProtectedRoute
// redirects here) - a fresh sign-in still needs this per-session second
// factor before reaching aal2, per spec section 43 / SECURITY.md.
export function MfaChallengePage() {
  const { session, isAdmin, loading, mfaStatus, refreshMfaStatus, signOut } = useAuth()
  const [factorId, setFactorId] = useState<string | null>(null)
  const [code, setCode] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    if (!session || mfaStatus !== 'challenge') return
    supabase.auth.mfa.listFactors().then(({ data }) => {
      const verified = data?.all.find((f) => f.factor_type === 'totp' && f.status === 'verified')
      setFactorId(verified?.id ?? null)
    })
  }, [session, mfaStatus])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!factorId) return
    setSubmitting(true)
    setError(null)
    const { error: verifyError } = await supabase.auth.mfa.challengeAndVerify({
      factorId,
      code,
    })
    setSubmitting(false)
    if (verifyError) {
      setError('Incorrect code. Please try again.')
      return
    }
    await refreshMfaStatus()
  }

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
  if (mfaStatus === 'enroll') return <Navigate to="/mfa-setup" replace />
  if (mfaStatus === 'ok') return <Navigate to="/" replace />

  return (
    <div className="flex h-screen items-center justify-center bg-gray-50">
      <form onSubmit={handleSubmit} className="w-80 rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h1 className="mb-2 text-lg font-semibold">Two-factor verification</h1>
        <p className="mb-4 text-sm text-gray-600">
          Enter the 6-digit code from your authenticator app.
        </p>
        <input
          type="text"
          inputMode="numeric"
          pattern="[0-9]*"
          maxLength={6}
          required
          autoFocus
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className="mb-3 w-full rounded border border-gray-300 px-3 py-2 text-sm"
        />
        {error && <p className="mb-3 text-sm text-red-600">{error}</p>}
        <button
          type="submit"
          disabled={submitting || !factorId}
          className="mb-2 w-full rounded bg-gray-900 px-3 py-2 text-sm text-white disabled:opacity-50"
        >
          {submitting ? 'Verifying...' : 'Verify'}
        </button>
        <button type="button" onClick={signOut} className="w-full text-sm text-gray-500 underline">
          Sign in with a different account
        </button>
      </form>
    </div>
  )
}
