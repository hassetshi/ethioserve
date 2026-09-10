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
- All 31 migrations applied (`supabase db push`) — matches dev/staging's
  schema exactly, including both bugs the subscriptions feature's live
  testing caught and fixed, plus the free-plan promotion and pre-seeded
  provider claim workflow (see "Free launch promotion & pre-seeded
  listings" below).
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

## Free launch promotion & pre-seeded listings

Production now carries real supply, not just infrastructure: 73 real
Ethiopian-owned DC-area businesses (`scripts/data/dc-lead-list.csv`, a
vetted lead list) were imported as verified, publicly searchable provider
listings via `scripts/import-dc-lead-list.mjs` — 0 skipped for city or
category. Each is on the new free launch-promotion plan
(`platform_settings.subscription_plan_free`, added by
`20260909000027_free_plan_promotion.sql`), which is offered (and every
seeded listing's `current_period_end`) through **2026-12-09** — set at
the moment the migration was applied to *this* project, independently of
when it ran on dev/staging, since production's is the date that actually
matters for the real promotion.

This required two schema changes beyond the promotion itself, both
applied and imported cleanly here:
- 9 new MD/VA cities plus reactivating Silver Spring, MD
  (`20260909000028_dmv_cities.sql`) — the lead list spans the DMV region,
  not just DC proper.
- 12 new business categories (Restaurant, Grocery, Coffee Shop & Bakery,
  Driving School, Real Estate, etc. — `20260909000029_dmv_business_categories.sql`)
  since the existing 5 were all home-services trades with no overlap.

A pre-seeded listing has no owner (`provider_profiles.user_id is null`,
made nullable by `20260909000030_provider_claims.sql`, which also added
`provider_claim_requests`/`provider_leads` and the
`request_provider_claim`/`approve_provider_claim`/`reject_provider_claim`
RPCs). The real business owner requests to claim their listing from the
app; an admin reviews and approves/rejects manually in admin-web's new
**Claim requests** page. This full claim flow — request, admin approval,
ownership transfer, role promotion, and the approval notification — was
verified live end-to-end against **both** dev/staging and production
itself: a real claim on "Selam Injera Bakery" was submitted from the
production mobile app and approved via admin-web's production build,
confirmed via direct DB query (`user_id` set, `role` promoted, the
"Claim approved" notification created).

**Deploy discipline note**: these 5 migrations were pushed via direct
`supabase db push` CLI (after explicitly relinking from dev to the
production ref — the CLI defaults to whatever was last linked, which was
production from the original bootstrap, so this is a real footgun worth
double-checking every time), not via the `Production Deploy` GitHub
Action as the release checklist below otherwise mandates. No GitHub API
token was available in that session to trigger `workflow_dispatch`. The
import script (`IMPORT_DATABASE_URL` pointed at production) has no
GitHub Action equivalent at all — it's a manual, deliberate one-off by
design (see the script's own comments). Worth reconciling the workflow's
migration state next time it runs, to confirm it doesn't consider
anything out of sync.

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
used through dev/staging does not include them. Chosen fix: an external
backup instead of upgrading the plan.

[.github/workflows/production-backup.yml](.github/workflows/production-backup.yml)
runs `pg_dump` against production daily (`0 8 * * *` UTC, plus manual
`workflow_dispatch`) and uploads a compressed, `pg_restore`-compatible
dump as a private GitHub Actions artifact, retained 90 days (GitHub's
maximum for artifacts — a longer archive would need external storage
instead). Reuses the `SUPABASE_PROD_PROJECT_REF`/`SUPABASE_PROD_DB_PASSWORD`
secrets `production-deploy.yml` already has; no new secrets needed.

**Known limitations, honestly**: GitHub disables scheduled workflows on
a repo with no push activity in 60 days, and can delay cron runs during
high platform load — acceptable for a free safety net, but worth
actually checking the Actions tab shows recent successful runs before
trusting it, not just assuming the cron fired. `pg_dump` itself wasn't
runnable locally to test end-to-end (no PostgreSQL client tools on this
dev machine) — the connection credentials are proven working (the exact
same host/user/password this session already used repeatedly via direct
Postgres access), but **the workflow's first actual run should be
confirmed manually** (Actions tab → Production Backup → Run workflow →
check it succeeds and produces a real artifact) rather than assumed
correct from the file alone.
[ ] Restore not yet tested — an untested backup is not a backup. Test a
real `pg_restore` (into a scratch database, never over production or
dev) at least once before relying on this for real launch.

## Monitoring and alerting

Lightweight plan for now, matching the "architecture only" pattern used for
Phase 12 payments — deferred until there's real traffic to monitor, not
because it doesn't matter:

- **Today**: Supabase's own dashboard (Logs & Reports) already covers API
  errors, database errors, and auth failures with no extra setup — this is
  free and already available on the production project the moment it
  exists. Check it manually; there's no alerting on top of it yet.
- [x] **Sentry scaffolding built**, same "no-op until configured" pattern as
  `isSupabaseConfigured`: `mobile`'s `EnvConfig.sentryDsn` /
  `admin-web`'s `env.sentryDsn`, both wired into their app's entry point
  (`main.dart`'s `SentryFlutter.init`, `main.tsx`'s `Sentry.init`), reading
  from a new `SENTRY_DSN` / `VITE_SENTRY_DSN` env key (added to every
  env file, left empty). **Still needed**: sign up for Sentry's free
  tier, create one project per app, and fill the two real DSNs into
  `mobile/env/production.json` and `admin-web/.env.production`
  (gitignored, same pattern as every other key there) — nothing reports
  to Sentry until that's done.
- **Before real users**: a simple external uptime check (e.g. UptimeRobot's
  free tier) against the `ai-search` Edge Function endpoint, so an outage
  is caught proactively rather than by an angry user. Not started.
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
- [x] RLS verified on production: `security-tests.mjs` (now configurable
      via `SECURITY_TEST_*` env vars — see the script's own comments) run
      against production with `DEV_DATABASE_URL` pointed there, using a
      temporary throwaway customer identity (created via the same direct
      `auth.users` insert `dev-seed-second-test-user.sql` uses, for RLS
      simulation only — never a real login) and "Excellent Workflows" as
      the test provider. 26/26 checks passed after one investigation: the
      first run showed 25/26, with "a verified provider WITH an active
      subscription appears in search" failing — root-caused to
      `search_providers`'s `limit least(p_limit, 50)` cap combined with
      production now genuinely having 74 eligible providers (the 73 seeded
      listings + this one), not an RLS gap — confirmed by a direct count
      query matching the RPC's own `where` clause. Every temporary change
      (the test provider's `verification_status`, the throwaway identity)
      was fully reverted/deleted afterward — no permanent fake data left
      in production.
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
- [x] A real claim request submitted and approved against the *production*
      database: `+12024060395` requested "Selam Injera Bakery" from the
      real mobile app (production env), approved via admin-web's Claim
      requests page (production build), confirmed live —
      `provider_profiles.user_id` set, `users.role` promoted to
      `provider`, and the "Claim approved" notification row created.
- [x] A real, live-mode Stripe transaction: "Excellent Workflows"
      (registered as a genuine new provider, Washington DC-area) subscribed
      to the Professional plan ($29/month) via the native PaymentSheet on
      the production build, using a real card. Confirmed via direct DB
      query — real `cus_`/`sub_` Stripe IDs, `status: active`,
      `current_period_end` one real month out. This surfaced a real gap
      along the way: production's `platform_settings` had never had live
      Stripe Price objects created for the paid plans (only the free plan
      was configured) — `scripts/create-stripe-subscription-prices.mjs`
      needs a `service_role` key it's deliberately never had, so the two
      Products/Prices were created directly via the Stripe API instead
      (using a narrowly-scoped restricted key, Products+Prices write only,
      created and revoked for this one-off task) and `stripe_price_id`
      written straight to `platform_settings` via direct Postgres access.
      This subscription is intentionally left active, not cancelled —
      it's a real business's real listing now, not disposable test data.
- [x] Mobile app actually builds and runs on a real Android device/emulator
      — confirmed live: real categories loaded from the dev Supabase
      project over HTTPS, with the dev machine's Norton SSL-interception
      still active. Needed two separate fixes (Android's platform trust
      store and `dart:io`'s independent one are not the same thing — see
      LOCAL_DEVELOPMENT.md's "Known gotchas" for the full breakdown),
      the second of which is shipped in `mobile/lib/main.dart`
      (debug-only). A physical device wasn't tested, only the emulator —
      worth a quick sanity check on real hardware before relying on this
      being fully equivalent, though nothing about the fix is
      emulator-specific.
