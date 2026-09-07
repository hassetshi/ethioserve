// Vite only exposes import.meta.env vars prefixed VITE_. Only the Supabase
// anon key belongs here — the service-role key must never ship in a
// client-side bundle (spec sections 7, 25, 31).
export const env = {
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL as string,
  supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY as string,
  environment: (import.meta.env.VITE_ENVIRONMENT as string) || 'development',
} as const

export const isSupabaseConfigured = Boolean(env.supabaseUrl && env.supabaseAnonKey)
