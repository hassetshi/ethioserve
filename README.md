# EthioServe

Ethiopian services marketplace connecting customers with local service providers, starting in Addis Ababa.

## Repository layout

```
EthioServe/
├── mobile/            Flutter app (customer + provider), Android primary, iOS secondary
├── admin-web/         Admin web app (React + Vite + TypeScript + Tailwind), Phase 10
├── supabase/          Postgres migrations, RLS policies, Edge Functions
├── docs/              Design/reference docs that don't fit the top-level *.md files
├── .env.example       Reference list of every config value used across the project
└── ARCHITECTURE.md, DATABASE.md, SECURITY.md, ... (see below)
```

## Documentation

| File | Covers |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Tech stack decisions, state management choice, folder structure |
| [DATABASE.md](DATABASE.md) | Schema, RLS model, migrations workflow |
| [SECURITY.md](SECURITY.md) | RLS, auth, secrets handling, admin security |
| [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) | Running the app locally |
| STAGING.md, PRODUCTION.md, DEPLOYMENT.md | Filled in starting Phase 15/16 |
| API.md, AI.md | Filled in starting Phase 11/12 |
| TESTING.md, TROUBLESHOOTING.md | Filled in as test suites/known issues accumulate |

## Current status

Phase 2 (authentication, users, profiles, roles) is complete. Phase 1 (project
setup):

- Git repository initialized.
- Full Supabase schema authored: all tables from the spec, RLS policies, booking
  state-machine trigger, rating aggregation trigger, and a server-side paginated
  provider search RPC (`supabase/migrations/`).
- Flutter app scaffolded (Riverpod + go_router + Supabase client + English/Amharic
  localization), with a working splash → language selection → home flow.
  `flutter analyze` is clean and `flutter test` passes.

A dev Supabase project is connected and live: 11 migrations are applied,
RLS/seed data verified against the real REST API. Config lives in
`mobile/env/development.json` (gitignored).

Phase 2 adds: phone-OTP login/verification screens, a Profile screen, and
router-level redirect logic gating every route on locale + auth state + role
(`mobile/lib/features/auth/`, `mobile/lib/features/profile/`,
`mobile/lib/core/router/app_router.dart`).

Phase 3 adds: real categories/services browsing and a full provider profile
screen (`mobile/lib/features/catalog/`, `mobile/lib/features/providers/`),
Storage buckets for provider photos/documents, and a starter services
catalog. Real phone-OTP delivery is now confirmed working (Twilio
configured) — see ARCHITECTURE.md.

Phase 4 adds: provider registration ("Become a provider" on the Profile
screen), a Provider Dashboard, adding offered services, and verification
document upload — backed by a `SECURITY DEFINER` RPC for the
customer-to-provider role promotion, since RLS correctly blocks that from a
plain client update.

Phase 5 adds: a real Home search field (service name search, English/Amharic),
and a generalized provider search-results screen (city, rating, and an
opt-in "Near me" location filter) shared by both the category-browse and
text-search entry points.

Phase 6 adds: the full booking flow — request, confirmation, live-tracking
details (Supabase Realtime), and bookings lists for both customer and
provider. Along the way, fixed a real gap in the Phase 1 booking trigger: it
only validated which status *values* were reachable, not *who* could set
them, so a customer could have accepted their own booking. Verified live
with two distinct test identities that this is now correctly enforced.

Phase 7 adds: server-side notification generation (new booking, every status
change) and an in-app notification center with a live unread badge. Actual
push delivery to the device tray is behind a `PushNotificationService`
abstraction with a no-op default — wiring in Firebase Cloud Messaging is a
pending decision (see ARCHITECTURE.md).

Phase 8 adds: booking-scoped chat (text + images) via Supabase Realtime,
reached from Booking Details. The schema/RLS for this were already correct
from Phase 1; verified live that an unauthenticated read returns nothing and
a spoofed insert is correctly rejected.

Phase 9 adds: leave-a-review on completed bookings, and a reviews +
provider-response section on the Provider Profile screen. Found and fixed
two real bugs along the way — a provider could have overwritten a
customer's rating via the "respond" policy, and a legitimate review
submission was being rejected by an unrelated admin-only guard reacting to
its own rating-recalculation side effect. Both fixed and verified live with
two real test identities (see ARCHITECTURE.md for the full story, including
a first fix attempt that turned out to be wrong for Supabase's actual
connection model). 30 tests passing.

Phase 10 adds `admin-web/`: a separate React + Vite + TypeScript + Tailwind
app (spec section 13 requires this be a different codebase from the mobile
app, never folded into it) covering the MVP admin scope — dashboard, users,
provider verification (review submitted documents, approve/reject/suspend),
categories, services, bookings. Getting it actually working end-to-end
turned into a genuine debugging saga — see ARCHITECTURE.md's Phase 10
section for the full story of ruling out a known supabase-js bug, a Fast
Refresh/duplicate-client issue, and finally landing on the real cause: the
dev machine's system clock was ~3 hours off from real time, which broke
Supabase's token-freshness check regardless of any code here.

Phase 11 adds AI search: a Supabase Edge Function calls Claude to classify a
free-text query (English or Amharic) against the platform's real
categories/services, validates every id it returns before trusting it, and
feeds the result into the same search RPC manual search already uses.
Verified live with the spec's own example queries in both languages. See
AI.md for the full pipeline.

Phase 12 adds payments — architecture-only per the spec's own MVP scope
allowance, but with cash payments genuinely working end-to-end (no external
provider needed for that): a `record_cash_payment` RPC only the assigned
provider can call, computing the commission split server-side from a
configurable rate (never hard-coded). Digital payment (Chapa/Telebirr/etc.)
sits behind the same interface, currently returning a clear "not available
yet" until a real provider is configured. 34 tests passing.

Phase 13 hardens the test suite: widget tests for the two screens that had
none (login, provider profile), a full integration test driving the real
app through language selection → login → OTP → browsing → booking request →
confirmation, and `scripts/security-tests.mjs` — 18 automated RLS/
authorization checks formalizing what had been verified ad-hoc since Phase
4, confirmed idempotent. Writing the integration test surfaced a real bug
in `FakeAuthRepository` (a non-reactive fake stream was silently hiding
login-triggered navigation from every earlier test); fixed and documented
in ARCHITECTURE.md. 38 tests passing.

Phase 14 adds CI: two path-filtered GitHub Actions workflows, one for
`mobile/` (format check, analyze, all 38 tests) and one for `admin-web/`
(lint, type-check + build), both running on every PR and on pushes to
`develop`/`staging`/`main`. Neither needs real Supabase credentials to
pass. See DEPLOYMENT.md for the full breakdown and the one piece that
still needs a manual step in the GitHub UI (branch protection on `main`).

Phase 15 adds an automated staging deploy: pushing to the `staging` branch
runs database migrations and redeploys the AI search edge function via
GitHub Actions. Staging deliberately shares the dev Supabase project for
now rather than a fully isolated environment — see STAGING.md for the
tradeoff and when to revisit it.

Not yet done (tracked toolchain gap — see the note in LOCAL_DEVELOPMENT.md):

- Android SDK isn't installed, so the app can't yet be run/built for Android
  (the primary target platform) — static analysis, unit/widget tests, and
  Flutter's web/Windows desktop targets work today.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full phase plan (Phases 2–17).
