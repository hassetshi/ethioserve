# Production

Filled in at Phase 16. Requirements to carry forward from the spec (sections
24, 38, 40–42) when that happens:

- Dedicated production Supabase project, database, storage, API config,
  payment credentials, notification configuration — never shared with
  dev/staging.
- Production secrets never committed to git (CI/CD secret store only).
- Automated backups, with documented frequency/retention/restore procedure,
  tested periodically.
- Monitoring + alerting for API errors, database errors, auth failures, app
  crashes, slow queries, AI errors, payment failures, notification failures,
  booking failures.
- Full production release checklist (spec section 38) run before every
  release, not just the first one.
