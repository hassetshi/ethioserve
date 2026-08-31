# Deployment

Filled in starting Phase 15 (staging deployment). Summary of the target
pipeline from the spec, recorded now so the CI/CD work in Phase 14 is built
toward the right shape:

```
feature/* → develop → staging → main → production
```

- All production changes go through pull requests; direct pushes to `main` are
  not allowed (spec section 26).
- CI (GitHub Actions, added Phase 14) runs on every PR: install deps, format
  check, static analysis, unit tests, widget tests, build where practical.
- Release flow: `develop` → staging build (QA/UAT) → `release/vX.Y.Z` branch →
  regression testing → Android App Bundle + iOS archive → Google Play
  Internal → Closed → staged production rollout (5% → 20% → 50% → 100%);
  Apple TestFlight → Internal → External → App Review → Production.
- See [STAGING.md](STAGING.md) and [PRODUCTION.md](PRODUCTION.md) (filled in
  when those environments actually exist) for environment-specific details,
  and the production release checklist in the original spec (section 38) for
  the full pre-launch gate.
