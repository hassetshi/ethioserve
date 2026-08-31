# Security

## Row Level Security (RLS)

RLS is enabled on every table (`supabase/migrations/20260831000008_rls_policies.sql`).
Summary of who can do what:

| Table | Customer | Provider | Admin |
|---|---|---|---|
| `users` / `profiles` | own row only | own row only | all |
| `provider_profiles` | read active ones; read own if also a provider | full read; write own (except admin fields) | all |
| `provider_services` / `availability` / `photos` | read (if provider active) | manage own | all |
| `provider_documents` | — | manage own | review/verify |
| `categories` / `services` / `cities` / `languages` | read active | read active | manage |
| `bookings` | create; read/update own | read/update assigned | all |
| `booking_status_history` | read own | read own | all (append only, trigger-written) |
| `reviews` | insert only for own completed booking; read all | respond to own | all |
| `messages` | read/send within own booking | read/send within own booking | all |
| `notifications` / `favorites` | own only | own only | read all |
| `payments` / `subscriptions` | read own | read own | write (via backend, see below) |
| `disputes` | create/read own | create/read own | resolve |
| `audit_logs` | — | — | read only |

Four `SECURITY DEFINER` helper functions back most of these policies:
`is_admin()`, `is_provider()`, `owns_provider_profile(id)`,
`is_booking_participant(id)`. They're `SECURITY DEFINER` so that, e.g., a policy
on `bookings` can check the caller's role without depending on the caller
already having read access to `public.users` via *its own* RLS policy — each
function does exactly one narrowly-scoped `EXISTS`/lookup, nothing broader.

**Never bypass RLS from the mobile app or admin-web client.** Payments,
subscriptions, and audit log writes are only ever performed by trusted server
code (Edge Functions) using the Supabase **service-role key**, which never
ships in the Flutter app or the admin-web client bundle (spec sections 7, 20, 31).

## Secrets

- `SUPABASE_ANON_KEY` (public/publishable): safe to compile into the app; RLS
  is what actually protects data, not secrecy of this key.
- `SUPABASE_SERVICE_ROLE_KEY`: server-only (Edge Functions, admin-web backend
  if it has one). Never in `mobile/`, never in a client bundle, never committed.
- All real secrets live in gitignored files (`mobile/env/*.json`,
  `admin-web/.env*`) or the CI/CD secret store — never in git history. See
  `.env.example` for the full list of names.

## Logging

`lib/core/logging/app_logger.dart` is the single logging chokepoint in the
mobile app. Per spec section 29/24, never log: passwords, OTP codes, payment
secrets, API keys, or other sensitive personal information — including inside
a log message's free-text `context`.

## Error handling

`lib/core/errors/app_exception.dart` defines the exception hierarchy the UI is
allowed to catch and render (`AppException.userMessage`, always a generic,
translated string). Raw exceptions/stack traces are logged via `AppLogger`,
never shown to the user (spec section 29).

## Admin security

Deferred to Phase 10 (admin-web build): MFA, session expiration, and
restricted-operation logging are implemented then, not simulated now. Tracked
here so it isn't forgotten — see spec section 43.

## Storage

`provider_documents` (verification documents) must be stored in a **private**
Supabase Storage bucket with a bucket policy mirroring the table's RLS (owner +
admin only) — configured when Storage is wired up in Phase 4.
