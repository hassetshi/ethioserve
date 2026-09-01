import { useEffect, useRef } from 'react'
import { useAuth } from '../context/auth-context'

const DEFAULT_TIMEOUT_MS = 15 * 60 * 1000 // 15 minutes
const ACTIVITY_EVENTS = ['mousedown', 'keydown', 'scroll', 'touchstart'] as const

// Spec section 43 calls for admin session expiration. Supabase's own JWT
// expiry (1 hour) plus this client's autoRefreshToken:false (see
// lib/supabase.ts) already means a session can't silently live forever, but
// that's independent of whether anyone is actually at the keyboard. This
// adds an explicit inactivity timeout on top, since an unattended admin tab
// on a shared or unlocked computer is the more realistic risk.
export function useIdleLogout(timeoutMs: number = DEFAULT_TIMEOUT_MS) {
  const { signOut } = useAuth()
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    function resetTimer() {
      if (timerRef.current) clearTimeout(timerRef.current)
      timerRef.current = setTimeout(() => {
        signOut()
      }, timeoutMs)
    }

    resetTimer()
    ACTIVITY_EVENTS.forEach((event) => window.addEventListener(event, resetTimer))

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current)
      ACTIVITY_EVENTS.forEach((event) => window.removeEventListener(event, resetTimer))
    }
  }, [timeoutMs, signOut])
}
