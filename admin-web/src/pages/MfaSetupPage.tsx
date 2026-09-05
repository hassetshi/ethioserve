import { useEffect, useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/auth-context'
import { supabase } from '../lib/supabase'

// Forced on any admin without a verified TOTP factor (ProtectedRoute redirects
// here) - spec section 43 / SECURITY.md's MFA requirement is mandatory, not
// opt-in, since this is the only admin surface in the system.
export function MfaSetupPage() {
  const { session, isAdmin, loading, mfaStatus, refreshMfaStatus } = useAuth()
  const [factorId, setFactorId] = useState<string | null>(null)
  const [qrCode, setQrCode] = useState<string | null>(null)
  const [starting, setStarting] = useState(true)
  const [code, setCode] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function startEnrollment() {
    setStarting(true)
    setError(null)
    setQrCode(null)
    // A previous incomplete attempt leaves an unverified factor behind, and
    // Supabase caps how many unverified TOTP factors one user can hold -
    // reuse it rather than piling up a new one every time this page loads.
    const { data: factors } = await supabase.auth.mfa.listFactors()
    const pending = factors?.all.find(
      (f) => f.factor_type === 'totp' && f.status === 'unverified',
    )
    if (pending) {
      // enroll() is the only call that returns the QR code/secret - an
      // already-created unverified factor can't have it re-fetched, so
      // this state only offers "start over" below, not a QR image.
      setFactorId(pending.id)
      setStarting(false)
      return
    }
    const { data, error: enrollError } = await supabase.auth.mfa.enroll({
      factorType: 'totp',
      friendlyName: 'EthioServe Admin',
    })
    if (enrollError || !data) {
      setError(enrollError?.message ?? 'Could not start MFA setup.')
    } else {
      setFactorId(data.id)
      setQrCode(data.totp.qr_code)
    }
    setStarting(false)
  }

  useEffect(() => {
    if (!session || mfaStatus !== 'enroll') return
    async function run() {
      await startEnrollment()
    }
    run()
  }, [session, mfaStatus])

  async function handleRestart() {
    if (factorId) await supabase.auth.mfa.unenroll({ factorId })
    setFactorId(null)
    await startEnrollment()
  }

  async function handleVerify(e: FormEvent) {
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
  if (mfaStatus === 'challenge') return <Navigate to="/mfa-challenge" replace />
  if (mfaStatus === 'ok') return <Navigate to="/" replace />

  return (
    <div className="flex h-screen items-center justify-center bg-gray-50">
      <div className="w-96 rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <h1 className="mb-2 text-lg font-semibold">Set up two-factor authentication</h1>
        <p className="mb-4 text-sm text-gray-600">
          Required for admin accounts. Scan this code with an authenticator app (Google
          Authenticator, Authy, 1Password, etc.), then enter the 6-digit code it shows.
        </p>
        {starting && <p className="mb-4 text-sm text-gray-500">Loading...</p>}
        {!starting && qrCode && (
          <img src={qrCode} alt="Scan with your authenticator app" className="mx-auto mb-4 h-48 w-48" />
        )}
        {!starting && !qrCode && (
          <div className="mb-4 text-sm text-gray-600">
            <p>A previous setup attempt wasn't finished, and its code can't be shown again.</p>
            <button type="button" onClick={handleRestart} className="mt-2 text-sm text-gray-900 underline">
              Start over
            </button>
          </div>
        )}
        <form onSubmit={handleVerify}>
          <label className="mb-1 block text-sm text-gray-600">6-digit code</label>
          <input
            type="text"
            inputMode="numeric"
            pattern="[0-9]*"
            maxLength={6}
            required
            value={code}
            onChange={(e) => setCode(e.target.value)}
            className="mb-3 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          />
          {error && <p className="mb-3 text-sm text-red-600">{error}</p>}
          <button
            type="submit"
            disabled={submitting || !factorId}
            className="w-full rounded bg-gray-900 px-3 py-2 text-sm text-white disabled:opacity-50"
          >
            {submitting ? 'Verifying...' : 'Verify and enable'}
          </button>
        </form>
      </div>
    </div>
  )
}
