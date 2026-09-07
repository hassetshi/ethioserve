import type { Session } from '@supabase/supabase-js'
import { useEffect, useState, type ReactNode } from 'react'
import { supabase } from '../lib/supabase'
import { AuthContext, type MfaStatus } from './auth-context'

// signInWithPassword succeeds (and returns a full session) at aal1 even for
// a user with a verified TOTP factor - Supabase doesn't gate password
// sign-in on MFA itself, the app has to check the assurance level
// afterward. Module-level (not a component-local closure) so it has a
// stable reference for both the effect and refreshMfaStatus below.
async function computeMfaStatus(session: Session | null): Promise<MfaStatus> {
  if (!session) return 'checking'
  const { data, error } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
  if (error || !data) return 'checking'
  if (data.currentLevel === 'aal2') return 'ok'
  if (data.nextLevel === 'aal2') return 'challenge'
  return 'enroll'
}

/// Real authorization is enforced server-side by RLS (`is_admin()` on every
/// admin-only policy) — this client-side check only decides what the admin
/// UI shows; it is never the actual security boundary (spec section 43:
/// "Never allow ordinary users to access admin APIs").
export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)
  const [mfaStatus, setMfaStatus] = useState<MfaStatus>('checking')

  useEffect(() => {
    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession)
    })

    supabase.auth.getSession().then(({ data }) => setSession(data.session))

    return () => listener.subscription.unsubscribe()
  }, [])

  // Exposed so MfaSetupPage/MfaChallengePage can re-check immediately after
  // a successful verify() rather than waiting on the next session change.
  async function refreshMfaStatus() {
    setMfaStatus(await computeMfaStatus(session))
  }

  // Re-checked on every session change so a fresh sign-in always lands on
  // 'enroll' or 'challenge' before 'ok' (persistSession is off, so there's
  // no stale aal2 to worry about surviving a reload).
  useEffect(() => {
    let cancelled = false

    computeMfaStatus(session).then((status) => {
      if (!cancelled) setMfaStatus(status)
    })

    return () => {
      cancelled = true
    }
  }, [session])

  useEffect(() => {
    let cancelled = false

    async function checkAdmin() {
      if (!session) {
        setIsAdmin(false)
        setLoading(false)
        return
      }
      setLoading(true)
      const { data } = await supabase
        .from('users')
        .select('role')
        .eq('id', session.user.id)
        .maybeSingle()
      if (!cancelled) {
        setIsAdmin(data?.role === 'admin')
        setLoading(false)
      }
    }

    checkAdmin()
    return () => {
      cancelled = true
    }
  }, [session])

  async function signIn(email: string, password: string) {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    return error ? 'Invalid email or password.' : null
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  return (
    <AuthContext.Provider
      value={{ session, isAdmin, loading, mfaStatus, refreshMfaStatus, signIn, signOut }}
    >
      {children}
    </AuthContext.Provider>
  )
}
