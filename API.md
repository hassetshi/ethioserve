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

### `ai-search` (Phase 11)

`POST /functions/v1/ai-search`

Request: `{ "query": string }` (max 500 chars, English or Amharic).

Response (200): either
```json
{ "matched": true, "categoryId": "uuid", "serviceId": "uuid | null" }
```
or
```json
{ "matched": false, "clarificationQuestion": "string" }
```

Calls Claude with the platform's current active categories/services and a
forced tool-use schema; every id Claude returns is re-checked against that
same catalog before being trusted (see AI.md). Requires the
`ANTHROPIC_API_KEY` secret (`supabase secrets set`), never exposed to the
client. Deployed with `--no-verify-jwt` since it's a stateless classifier
with no per-user data — any request bearing the project's anon key can call it.

Planned, filled in when its phase lands:

- Payment initialization/verification/webhook handling (Phase 12) — must run
  server-side; the mobile client never confirms its own payment (spec section 20).
