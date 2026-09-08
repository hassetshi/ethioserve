# Deployment

Full staging/production rollout is filled in starting Phase 15. Summary of
the target pipeline from the spec:

```
feature/* → develop → staging → main → production
```

- All production changes go through pull requests; direct pushes to `main` are
  not allowed (spec section 26).
- Release flow: `develop` → staging build (QA/UAT) → `release/vX.Y.Z` branch →
  regression testing → Android App Bundle + iOS archive → Google Play
  Internal → Closed → staged production rollout (5% → 20% → 50% → 100%);
  Apple TestFlight → Internal → External → App Review → Production.
- See [STAGING.md](STAGING.md) and [PRODUCTION.md](PRODUCTION.md) (filled in
  when those environments actually exist) for environment-specific details,
  and the production release checklist in the original spec (section 38) for
  the full pre-launch gate.

## CI (Phase 14)

Two independent GitHub Actions workflows, each path-filtered so a PR that
only touches one half of the repo doesn't wait on the other:

- [.github/workflows/mobile-ci.yml](.github/workflows/mobile-ci.yml) —
  `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`
  (all 38 tests). Runs against `mobile/**` changes only.
- [.github/workflows/admin-web-ci.yml](.github/workflows/admin-web-ci.yml) —
  `oxlint`, then `tsc -b && vite build` (type-check + production build).
  Runs against `admin-web/**` changes only. No test script exists for
  admin-web yet (see TESTING.md's Phase 10 note on Vitest); lint + a
  successful type-checked build are the bar until that's added.

Both trigger on every pull request and on pushes to `develop`, `staging`,
and `main`. Neither needs real Supabase credentials to pass: mobile's
`EnvConfig` (`mobile/lib/core/config/env_config.dart`) and admin-web's `env`
module (`admin-web/src/lib/env.ts`) both degrade to empty/unconfigured
rather than throwing when the corresponding `--dart-define`/`VITE_*` values
are absent, so CI exercises the exact same source a real build would use
without any secrets in the workflow files.

**Done via the GitHub UI**, not expressible in YAML (spec section 26's "no
direct pushes to main"): branch protection on `main` — requires 1 PR
approval and both CI checks (`analyze-and-test`, `lint-and-build`) to pass;
force-pushes and deletions stay off (the default). Confirmed live via
`GET /repos/hassetshi/ethioserve/branches/main` returning `"protected":
true`. This was turned on only after the *first* PR into `main` ever
existed (see PRODUCTION.md's bootstrap notes — `main` had sat at the
project's very first commit until then), since GitHub needs at least one
real run of each check's name to offer it as a selectable required status
check.

## Staging deploy (Phase 15)

[.github/workflows/staging-deploy.yml](.github/workflows/staging-deploy.yml)
pushes database migrations and redeploys the `ai-search` edge function on
every push to `staging`. See STAGING.md for the full breakdown, including
the deliberate (and temporary) decision to point staging at the same
Supabase project as local dev rather than standing up a second one.

## Production deploy (Phase 16)

[.github/workflows/production-deploy.yml](.github/workflows/production-deploy.yml)
does the same as staging's, but manual-only (`workflow_dispatch`, no
automatic push trigger) against a genuinely separate production project.
The project itself doesn't exist yet — see PRODUCTION.md for the full
pre-launch checklist and what's still open (MFA, backups, monitoring).
