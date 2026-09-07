# Production

## Status: project created and bootstrapped, not yet live

Unlike staging (which deliberately shares the dev Supabase project — see
STAGING.md), production is a genuinely separate project: real user phone
numbers, addresses, payment records, and verification documents have no
business living anywhere near a project that local dev scripts
(`scripts/dev-db.mjs`) freely mutate. Phase 16 built everything that didn't
require the project to exist yet and deliberately held off on creating it;
it was created and bootstrapped in a later session, once real credentials
(Twilio, Anthropic) were available to configure it properly rather than
standing up an empty shell.

**The project**: `ethioserve-production` (ref `xkdtseqgwllobhhamezz`,
region `us-west-1`), in the same `Excellentworkflows` org as dev/staging.
Three unrelated older projects in that org (`excellent-AI`,
`AI-Powered-EdTech`, `Elis_care`) were deleted first to stay within the
free plan's project limit — the org remains on the free plan, which is
why backups (below) are still an open gap, not yet paid for.

**What's actually live on it right now**, all verified, not just deployed:
- All 26 migrations applied (`supabase db push`) — matches dev/staging's
  schema exactly, including both bugs the subscriptions feature's live
  testing caught and fixed.
- All 4 Edge Functions deployed (`ai-search`, `stripe-create-payment-intent`,
  `stripe-create-subscription`, `stripe-webhook`).
- Secrets set: `ANTHROPIC_API_KEY` (same key as dev/staging — a deliberate
  choice, see below), `STRIPE_SECRET_KEY` (**test-mode**, deliberately —
  see the release checklist's live-mode item), `STRIPE_WEBHOOK_SECRET`
  (its own dedicated webhook endpoint, `we_1UCONnJ4qEJXPhXVM3Bgj9V7`,
  confirmed to match dev/staging's exact `enabled_events` list rather than
  a guessed set).
- `ai-search` smoke-tested live with a real query ("I need a plumber" →
  correctly matched the Plumbing category).
- Catalog data confirmed reflecting the US pivot (Washington, DC active,
  not Addis Ababa) — inherited automatically from the migrations, not a
  separate step.
- Twilio phone auth configured to match dev/staging exactly (`twilio_verify`
  provider, not plain SMS) and verified live: a real OTP was sent to and
  received on a real US number.
- Production admin account created (`hassetshi@gmail.com`, Dashboard →
  Authentication → Users → Add user — never via SQL, see below for why),
  promoted to `role = 'admin'` in `public.users`, and MFA enrolled and
  verified on it (real TOTP factor, confirmed `status = 'verified'` in
  `auth.mfa_factors`).

**Why the admin account can't be created via SQL**: inserting directly
into `auth.users` bypasses Supabase's own password hashing and the linked
`auth.identities` row that a real sign-up/Admin-API path creates — the
account would exist but couldn't actually log in, or would be missing
invariants the rest of `auth.*` assumes hold. The Dashboard's "Add user"
(or the Admin API, which needs the `service_role` key — deliberately not
retrievable through this session, by design) both do this correctly.

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
  during this phase's checklist review): session-inactivity timeout,
  admin-action audit logging via `log_admin_action`, and (added later,
  once a provider decision was made) MFA via Supabase Auth's built-in TOTP
  support. See SECURITY.md for details.

## Bootstrap steps and their status

1. [x] Create the Supabase project (separate from dev/staging).
2. [x] Configure Twilio phone auth on it (same steps as Phase 2, against the
   new project) — done, verified with a real received OTP.
3. [x] Set `ANTHROPIC_API_KEY` and `STRIPE_SECRET_KEY` (test-mode) via
   `supabase secrets set` against it.
4. [x] Add GitHub Actions secrets: `SUPABASE_PROD_PROJECT_REF`
   (`xkdtseqgwllobhhamezz`), `SUPABASE_PROD_DB_PASSWORD` (reuses the
   existing `SUPABASE_ACCESS_TOKEN` — that token is account-level, not
   project-scoped). Set via the GitHub API (libsodium sealed-box encryption
   against the repo's Actions public key, same scheme `gh secret set` uses
   internally) using a short-lived fine-grained PAT scoped to just this
   repo's Secrets permission. Migrations/functions were pushed directly via
   the CLI for the initial bootstrap itself — this step is what makes the
   `Production Deploy` GitHub Action usable for every deploy *after* this
   one.
5. [x] Run `Production Deploy` via workflow_dispatch, verified succeeding
   (run 34124789600) — a no-op as expected, since the CLI bootstrap already
   applied everything it would do. This step surfaced a real, unrelated gap
   along the way: `main` had never actually been merged into since the very
   first commit (still sitting at Phase 1, 42 commits behind) —
   `workflow_dispatch` needs a workflow file present on the default branch
   to even be dispatchable, so `production-deploy.yml` didn't show up as a
   workflow at all until that first-ever PR into `main` landed. That PR also
   surfaced 8 files' worth of accumulated `dart format` drift that had been
   silently failing mobile-ci on every develop/staging push with nothing
   actually gating on it — fixed as part of getting the PR green.
6. [x] Create the production admin account (Dashboard → Authentication →
   Users, never via SQL) and enroll MFA on it.
7. [ ] Optionally add required-reviewer protection on the `production`
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

- [x] All migrations applied cleanly to the production project — applied
      via direct CLI push for the initial bootstrap, then confirmed the
      `Production Deploy` GitHub Action itself works (bootstrap step 5) with
      a real successful run; use that workflow, not the CLI, for every
      deploy from here on.
- [x] `ai-search` edge function deployed and smoke-tested with a real query.
- [ ] RLS verified on the production project: run
      `node scripts/security-tests.mjs` with `DEV_DATABASE_URL` pointed at
      *production* — the same 18+ checks that guard dev/staging. Deliberately
      not run yet: the script's trigger-level tests need fixed dev-seed
      identities (`scripts/dev-seed-sample-provider.sql` etc.) that
      production has no equivalent of, and production shouldn't carry
      permanent fake data — do this as a temporary seed-and-clean-up pass
      right before real launch, not casually during bootstrap.
- [x] No `service_role` key anywhere in `mobile/` or `admin-web/` — verified
      two ways: no source reference to `SERVICE_ROLE`/`service_role` in
      either `mobile/lib` or `admin-web/src` (so a bundler has nothing to
      pull in regardless), and confirmed by grepping the actual built
      output (`flutter build web`, `vite build`) directly — both clean.
      Re-run this before every release, not just once; a future change
      could still introduce a reference.
- [x] Production admin account exists (`hassetshi@gmail.com`), with a
      password distinct from dev/staging's admin password.
- [x] MFA on the admin account — built (Supabase Auth TOTP), verified live
      on both the dev/staging *and* production admin accounts (each starts
      unenrolled independently — enrolling on one doesn't cover the other).
      See SECURITY.md.
- [ ] Backups confirmed active (paid plan) or an external backup schedule
      confirmed running, with at least one successful test restore.
- [x] Branch protection on `main` is on (see DEPLOYMENT.md) — requires 1 PR
      approval and both `analyze-and-test` (mobile) and `lint-and-build`
      (admin-web) status checks to pass, confirmed live via the branch
      protection API.
- [x] Twilio phone auth verified working against the production project
      with a real phone number (`twilio_verify` provider, matching
      dev/staging's configuration).
- [x] Stripe switched from test-mode to live-mode keys. Important
      correction along the way: the account this project's `STRIPE_SECRET_KEY`
      had used all along (`acct_1RqIHSJ4qEJXPhXV`, "Excellentworkflows
      sandbox") is a genuine Stripe **sandbox** — `charges_enabled: false`
      permanently, not just a test-mode account — so it could never have
      taken live payments regardless of key swapping. Live mode instead
      points at the company's real, separate, fully-activated account
      (`acct_1T9oNlGSzs4e43tI` — confirmed `charges_enabled`,
      `payouts_enabled`, and `details_submitted` all `true` before wiring
      anything to it). Set: production's `STRIPE_SECRET_KEY` (live),
      `STRIPE_PUBLISHABLE_KEY` in `mobile/env/production.json` (gitignored,
      real values now filled in — see LOCAL_DEVELOPMENT.md's env-file
      pattern), and a **new** live-mode webhook endpoint
      (`we_1UD3eRGSzs4e43tIPQ8C9RiD`) pointed at production's
      `stripe-webhook` URL with its own live `STRIPE_WEBHOOK_SECRET` —
      confirmed matching the test-mode endpoint's exact `enabled_events` set
      rather than re-guessed. Dev/staging deliberately stay on the sandbox
      key; only production's secrets changed.
- [ ] At least one real (small) end-to-end Stripe transaction tested
      against live-mode keys before real customers rely on it. Still
      blocked on the same thing that blocked the test-mode verification
      earlier: `flutter_stripe_web`'s PaymentSheet doesn't reliably work in
      a browser, and real Android testing is still blocked by this dev
      machine's Norton SSL-interception issue. This is now a **real-money**
      test once it runs — small, deliberate, and only when you're ready.
- [ ] Mobile app actually builds and runs on a real Android device — not
      yet true as of Phase 16 (Android SDK gap, see README.md).
