# EthioServe

Ethiopian services marketplace connecting customers with local service providers, starting in Addis Ababa.

## Repository layout

```
EthioServe/
├── mobile/            Flutter app (customer + provider), Android primary, iOS secondary
├── admin-web/         Admin web application (added in Phase 10)
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

Phase 1 (project setup) is complete:

- Git repository initialized.
- Full Supabase schema authored: all tables from the spec, RLS policies, booking
  state-machine trigger, rating aggregation trigger, and a server-side paginated
  provider search RPC (`supabase/migrations/`).
- Flutter app scaffolded (Riverpod + go_router + Supabase client + English/Amharic
  localization), with a working splash → language selection → home flow.
  `flutter analyze` is clean and `flutter test` passes.

Not yet done (tracked toolchain gaps — see the note in LOCAL_DEVELOPMENT.md):

- No real Supabase project is connected yet; the migrations haven't been applied
  anywhere. Requires either Docker (for `supabase start` locally) or a real
  Supabase dev project.
- Android SDK isn't installed, so the app can't yet be run/built for Android
  (the primary target platform) — only static analysis, unit/widget tests, and
  Flutter's web/Windows desktop targets work today.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full phase plan (Phases 2–17).
