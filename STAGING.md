# Staging

## Deliberate scope decision: staging shares the dev Supabase project

Spec section 24 asks for staging to be "as close to production as
practical" and implies its own isolated environment. Phase 15 deliberately
did **not** stand up a second Supabase project — staging currently points
at the same project as local development
(`https://xvcwqkghhkuwvtdrmcey.supabase.co`). Reasoning, same category of
tradeoff as Phase 12's "architecture only" payments and Phase 7's deferred
push notifications: this is a solo-developer MVP build-out, a second paid
project buys isolation that has no one to violate yet (no QA team, no
external testers touching data concurrently with development), and the
automated deploy pipeline below is what actually needed proving at this
phase, not environment count. **This is a real gap once real users or a QA
team are involved** — revisit before Phase 17's store release, or sooner if
a second developer joins: a schema migration tested by CI against "staging"
today is the same database local dev scripts (`scripts/dev-db.mjs`,
`scripts/dev-seed-*.sql`) are freely mutating, so a broken local experiment
and a "staging" regression are indistinguishable until they aren't.

## Automated deploy (Phase 15)

[.github/workflows/staging-deploy.yml](.github/workflows/staging-deploy.yml)
runs `supabase db push` (migrations) then `supabase functions deploy
ai-search` against the shared project on every push to the `staging`
branch, or manually via workflow_dispatch. Requires three GitHub Actions
secrets (Settings → Secrets and variables → Actions on the repo):
`SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`.
Edge function secrets (`ANTHROPIC_API_KEY`) were set once via `supabase
secrets set` in Phase 11 and persist on the project — the workflow only
redeploys function code, not those secrets.

For the mobile app, `mobile/env/staging.json` (gitignored, mirrors
`development.json` since they're the same project) drives
`--dart-define-from-file=env/staging.json` staging builds — see
LOCAL_DEVELOPMENT.md.

admin-web has no staging *hosting* deployment yet (Vercel/Netlify/etc.) —
QA of the admin flow today still means running `npm run dev` locally
against the shared project. Standing up a public staging URL for admin-web
is deferred to whenever a non-developer needs to click through it without
a local checkout.

## Carried forward from the spec (section 24), once staging is truly isolated

- As close to production as practical.
- Test users, test providers, sandbox payments — never real customer data
  unless anonymized and explicitly authorized.
- QA checklist: customer flow, provider flow, admin flow, AI search, Amharic
  UI, English UI, notifications, location, payments.
