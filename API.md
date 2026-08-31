# API

EthioServe has no separate REST API layer — the mobile app and admin-web talk
directly to Supabase (PostgREST auto-generated from the schema, protected by
RLS) plus a small number of Postgres RPCs and Edge Functions for logic that
can't safely live behind plain table access.

## RPCs (Postgres functions callable via Supabase client `.rpc()`)

| Function | Purpose | Added in |
|---|---|---|
| `search_providers(...)` | Paginated, filterable, geospatial provider search — the mobile app never selects raw `provider_profiles` rows for search | Phase 1 (`supabase/migrations/20260831000009_search_functions.sql`) |

## Edge Functions

None yet. Planned, filled in as their phases land:

- Payment initialization/verification/webhook handling (Phase 12) — must run
  server-side; the mobile client never confirms its own payment (spec section 20).
- AI search interpretation (Phase 11) — validates/sanitizes the AI's structured
  output before it ever reaches a database query (spec section 15).

This file is expanded with request/response shapes as each of these is built.
