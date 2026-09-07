import { createClient } from '@supabase/supabase-js'
import { env } from './env'

// autoRefreshToken and persistSession are both deliberately off. supabase-js
// has a known auto-refresh race (supabase/supabase-js#2126) that fires
// repeated concurrent refresh calls until Supabase's rate limiter kicks in
// and force-signs-out the user — that's what this admin app was hitting.
// Disabling autoRefreshToken alone wasn't enough: with persistSession still
// on, a recovered/stored session from a previous test kept getting treated
// as needing an on-demand refresh on every request, reproducing the same
// loop through a different code path. Disabling persistence too removes any
// stored session for that on-demand path to act on: nothing survives a page
// reload, and the admin signs in again — an acceptable trade-off for an
// internal tool, and one that doesn't depend on a fix that isn't in a
// stable supabase-js release yet.
export const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
    detectSessionInUrl: false,
  },
})
