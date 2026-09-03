# Production

## Status: pipeline built, project not yet created (Phase 16)

Unlike staging (which deliberately shares the dev Supabase project — see
STAGING.md), production must be a genuinely separate project: real user
phone numbers, addresses, payment records, and verification documents have
no business living anywhere near a project that local dev scripts
(`scripts/dev-db.mjs`) freely mutate. Phase 16 built everything that
doesn't require the project to exist yet, and deliberately held off on
actually creating it — there's no reason to stand up and pay for production
infrastructure before the app can even be installed anywhere (Android SDK
still isn't set up locally; no store listing exists — see Phase 17).

## What's ready now

- [.github/workflows/production-deploy.yml](.github/workflows/production-deploy.yml):
  pushes migrations and redeploys `ai-search`, but **manual-only**
  (`workflow_dispatch`, no automatic trigger on push to `main`) — a human
  clicking "Run workflow" is the deliberate safeguard, matching spec section
  26's "no direct pushes to main" spirit applied to production
  infrastructure itself, not just source code.
- `mobile/env/production.example.json` — template for the real
  (gitignored) `production.json` once the project exists.
- Admin-web security hardening that spec section 43 calls for and Phase 10
  never actually delivered despite SECURITY.md claiming otherwise (caught
  during this phase's checklist review): session-inactivity timeout and
  admin-action audit logging via `log_admin_action`. See SECURITY.md for
  what's done and what's still open (MFA).

## Before the production project is created, in order

1. Create the Supabase project (separate from dev/staging).
2. Configure Twilio phone auth on it (same steps as Phase 2, against the new
   project).
3. Run `supabase secrets set ANTHROPIC_API_KEY=...` against it (Phase 11's
   step, repeated for the new project — reuse the same key or issue a
   separate one, a billing/rate-limit decision, not a technical one).
4. Add GitHub Actions secrets: `SUPABASE_PROD_PROJECT_REF`,
   `SUPABASE_PROD_DB_PASSWORD` (reuses the existing `SUPABASE_ACCESS_TOKEN`
   — that token is account-level, not project-scoped).
5. Run `Production Deploy` via workflow_dispatch once, verify it succeeds.
6. Create the production admin account (Dashboard → Authentication → Users,
   same as Phase 10 — never via SQL, see ARCHITECTURE.md's Phase 10 story
   for why).
7. Optionally add required-reviewer protection on the `production`
   environment (Settings → Environments → production) as a second layer on
   top of the manual dispatch trigger — not load-bearing today since only
   one person has repo access, but cheap to turn on before anyone else gets
   write access.

## Backups

Supabase's automatic daily backups with point-in-time recovery are a
**paid-plan feature** (Pro tier and above) — the free tier this project has
used through dev/staging does not include them. This is a real, honest gap:
**do not launch with real user data on the free tier without either
upgrading the production project or standing up an external backup
(`pg_dump` on a schedule).** Once on a plan with backups: document the
actual retention window shown in the Supabase dashboard here, and test a
real restore at least once before launch — an untested backup is not a
backup.

## Monitoring and alerting

Lightweight plan for now, matching the "architecture only" pattern used for
Phase 12 payments — deferred until there's real traffic to monitor, not
because it doesn't matter:

- **Today**: Supabase's own dashboard (Logs & Reports) already covers API
  errors, database errors, and auth failures with no extra setup — this is
  free and already available on the production project the moment it
  exists. Check it manually; there's no alerting on top of it yet.
- **Before real users**: wire up crash/error reporting in the Flutter app
  and admin-web (Sentry's free tier covers both Flutter and browser JS) so
  app crashes and unhandled AI/payment/booking errors surface without
  someone having to notice a support complaint first.
- **Before real users**: a simple external uptime check (e.g. UptimeRobot's
  free tier) against the `ai-search` Edge Function endpoint, so an outage
  is caught proactively rather than by an angry user.
- Slow-query monitoring is a paid-plan Supabase feature (Query Performance)
  — revisit once real query volume exists to make it worth reading.

## Production release checklist

Run before every release to production, not just the first one:

- [ ] All migrations applied cleanly to the production project (via
      `Production Deploy`, never by hand).
- [ ] `ai-search` edge function deployed and smoke-tested with a real query.
- [ ] RLS verified on the production project: run
      `node scripts/security-tests.mjs` with `DEV_DATABASE_URL` pointed at
      *production* — the same 18+ checks that guard dev/staging.
- [ ] No `service_role` key anywhere in `mobile/` or `admin-web/` — grep the
      built bundle, not just the source, before shipping.
- [ ] Production admin account exists, and its password is not one used
      anywhere else.
- [ ] MFA on the admin account — **blocking until built**, see SECURITY.md.
- [ ] Backups confirmed active (paid plan) or an external backup schedule
      confirmed running, with at least one successful test restore.
- [ ] Branch protection on `main` is on (see DEPLOYMENT.md).
- [ ] Twilio phone auth verified working against the production project
      with a real phone number, not just dev/staging's.
- [ ] Stripe switched from test-mode to live-mode keys
      (`STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`), and a **new** live-mode
      webhook endpoint registered in the Stripe Dashboard pointed at the
      production project's `stripe-webhook` URL with its own live-mode
      `STRIPE_WEBHOOK_SECRET` — test-mode and live-mode webhook secrets are
      different values pointing at different Stripe environments, easy to
      leave on test-mode by mistake if not checked explicitly.
- [ ] At least one real (small) end-to-end Stripe transaction tested
      against live-mode keys before real customers rely on it.
- [ ] Mobile app actually builds and runs on a real Android device — not
      yet true as of Phase 16 (Android SDK gap, see README.md).
