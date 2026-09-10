import * as Sentry from '@sentry/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App.tsx'
import './index.css'
import { env } from './lib/env'

// No-ops when VITE_SENTRY_DSN is unset — same "optional until configured"
// pattern as isSupabaseConfigured.
if (env.sentryDsn) {
  Sentry.init({ dsn: env.sentryDsn, environment: env.environment })
}

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
)
