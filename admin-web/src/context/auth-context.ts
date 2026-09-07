import type { Session } from '@supabase/supabase-js'
import { createContext, useContext } from 'react'

// 'checking' covers the gap between a session existing and the AAL lookup
// resolving - ProtectedRoute treats it like `loading` rather than guessing.
// 'enroll': no verified TOTP factor yet (spec section 43's MFA requirement
// isn't met at all). 'challenge': a factor is verified but this session is
// still aal1 (e.g. a fresh sign-in hasn't completed the second factor yet).
// 'ok': aal2 - fully authenticated.
export type MfaStatus = 'checking' | 'enroll' | 'challenge' | 'ok'

export type AdminAuthState = {
  session: Session | null
  isAdmin: boolean
  loading: boolean
  mfaStatus: MfaStatus
  refreshMfaStatus: () => Promise<void>
  signIn: (email: string, password: string) => Promise<string | null>
  signOut: () => Promise<void>
}

// Split from AuthContext.tsx so that file exports only the AuthProvider
// component — mixing a component export with this hook/context in one file
// breaks Vite's Fast Refresh ("useAuth export is incompatible"), which was
// forcing full module-graph invalidations on every edit during development
// and ended up leaving two live Supabase client instances in the browser
// simultaneously (see lib/supabase.ts for what that caused).
export const AuthContext = createContext<AdminAuthState | undefined>(undefined)

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
