import type { Session } from '@supabase/supabase-js'
import { useEffect, useState, type ReactNode } from 'react'
import { supabase } from '../lib/supabase'
import { AuthContext } from './auth-context'

/// Real authorization is enforced server-side by RLS (`is_admin()` on every
/// admin-only policy) — this client-side check only decides what the admin
/// UI shows; it is never the actual security boundary (spec section 43:
/// "Never allow ordinary users to access admin APIs").
export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession)
    })

    supabase.auth.getSession().then(({ data }) => setSession(data.session))

    return () => listener.subscription.unsubscribe()
  }, [])

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
    <AuthContext.Provider value={{ session, isAdmin, loading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}
