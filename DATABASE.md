# Database

PostgreSQL via Supabase. All schema changes are migration files under
`supabase/migrations/`, applied in filename (timestamp) order. Never modify a
deployed database by hand (spec section 39) — always add a new migration file,
even for a one-line fix.

## Migration files

| File | Contents |
|---|---|
| `20260831000001_extensions_and_lookups.sql` | `pgcrypto`, `postgis`; `languages`, `cities`, `platform_settings` lookup tables; the shared `set_updated_at()` trigger function |
| `20260831000002_users_and_profiles.sql` | `users` (mirrors `auth.users`), auto-provisioning trigger, `profiles` |
| `20260831000003_provider_and_catalog.sql` | `categories`, `services`, `provider_profiles` (+ geography sync trigger, admin-fields guard), `provider_services`, `provider_availability`, `provider_photos`, `provider_documents` |
| `20260831000004_bookings.sql` | `bookings`, `booking_status_history`, the booking state-machine trigger |
| `20260831000005_reviews_messages_notifications.sql` | `reviews` (+ eligibility trigger, rating-aggregation trigger), `messages`, `notifications`, `favorites` |
| `20260831000006_payments_subscriptions_ads.sql` | `payments`, `subscriptions`, `advertisements` |
| `20260831000007_disputes_and_audit.sql` | `disputes`, `audit_logs` |
| `20260831000008_rls_policies.sql` | `is_admin()`/`is_provider()`/`owns_provider_profile()`/`is_booking_participant()` helper functions, RLS enabled + policies on every table |
| `20260831000009_search_functions.sql` | `search_providers()` — server-side paginated/filterable/geospatial provider search RPC |
| `20260831000010_seed_data.sql` | Initial languages, cities, categories, and the default booking commission rate |
| `20260831000011_profiles_nullable_names.sql` | Names are collected post-signup, not at OTP time; drops the `NOT NULL` constraint |
| `20260831000012_storage_buckets.sql` | `provider-photos` (public) and `provider-documents` (private) Storage buckets + their object-level RLS |
| `20260831000013_seed_services.sql` | Starter services (3 per category) — initial catalog content, not test data |
| `20260831000014_provider_registration.sql` | `register_as_provider()` — `SECURITY DEFINER` RPC that promotes `users.role` and creates `provider_profiles`, since RLS deliberately forbids a client from changing its own role directly |
| `20260831000015_booking_transition_actor_rules.sql` | Replaces `validate_booking_status_transition()` to also check *who* may make a transition (only the assigned provider can accept/decline/progress/complete; either participant can cancel), not just which status values are reachable. Also adds `bookings` to the `supabase_realtime` publication for live tracking. |
| `20260831000016_notifications.sql` | `device_tokens` table; `notify_new_booking()` and `notify_booking_status_change()` triggers that generate `notifications` rows server-side; adds `notifications` to the `supabase_realtime` publication for the unread-count badge |
| `20260831000017_messaging.sql` | `chat-images` private Storage bucket (RLS via `is_booking_participant()` on the path's booking-id segment); adds `messages` to the `supabase_realtime` publication for live chat |
| `20260831000018_reviews_field_ownership.sql` | `guard_review_field_ownership()` trigger: a provider responding to a review may only change `provider_response`, not the customer's rating/comment (the Phase 1 RLS policy allowed any column) |
| `20260831000019_fix_rating_cascade_vs_admin_guard.sql` | First (incorrect) attempt at fixing the rating-cascade-vs-admin-guard conflict below — superseded by 000020 |
| `20260831000020_fix_rating_cascade_properly.sql` | Correct fix: `recalculate_provider_rating()` now sets a transaction-local flag around its update, and `guard_provider_profile_admin_fields()` trusts it — see ARCHITECTURE.md Phase 9 for why the 000019 approach (`current_user <> session_user`) was wrong for Supabase's actual PostgREST connection model |

## Deliberate deviations from the literal field list in the spec

The spec's table-by-table field lists (its section 9) are the contract for *what
data exists*; a couple of fields were implemented as foreign keys into small
lookup tables instead of free text, because the spec's own non-functional
requirements (section 3, 4) call for exactly this:

- `provider_profiles.city` → `city_id uuid references cities(id)`. Spec section 3:
  "architecture must allow additional cities... without major code changes." A
  lookup table means adding Dire Dawa, Bahir Dar, etc. is an `INSERT`, not a
  migration.
- `users.language` / `profiles.preferred_language` → `references languages(code)`.
  Spec section 4: same reasoning, for Afaan Oromo/Tigrinya/Somali.

Every other field matches the spec's tables exactly, plus the required
`id` / `created_at` / `updated_at` on every major table (spec section 8).

## Row Level Security

RLS is enabled on every table; there is no table the mobile or admin-web client
can read/write without an explicit policy. See [SECURITY.md](SECURITY.md) for the
policy summary and the reasoning behind the `SECURITY DEFINER` helper functions.

## Server-enforced invariants (not just RLS)

Some rules can't be expressed as a row-level `CHECK` or a simple RLS policy
because they depend on related rows. These are enforced by `BEFORE`/`AFTER`
triggers, so they hold regardless of which client (mobile, admin-web, or a
future integration) makes the write:

- **Booking status transitions** (`validate_booking_status_transition`): the
  only legal moves are `requested → accepted|declined|cancelled`,
  `accepted → on_the_way|cancelled`, `on_the_way → in_progress|cancelled`,
  `in_progress → completed|cancelled`. As of Phase 6, it also checks *who*
  is making the change: only the assigned provider may set
  `accepted`/`declined`/`on_the_way`/`in_progress`/`completed`; either
  participant may set `cancelled`; admins bypass both checks. Every
  transition is also appended to `booking_status_history` automatically.
- **Review eligibility** (`validate_review_eligibility`): a review can only be
  inserted if its `booking_id` refers to a `completed` booking, and the
  `customer_id`/`provider_id` on the review match that booking.
- **Provider rating aggregation** (`recalculate_provider_rating`): keeps
  `provider_profiles.rating`/`review_count` in sync automatically; the app never
  computes or writes these directly. Runs as `SECURITY DEFINER` and sets a
  transaction-local flag (`app.internal_rating_update`) around its own
  update so the admin-fields guard below trusts it (see Phase 9 in
  ARCHITECTURE.md for the two wrong turns before landing on this).
- **Provider self-verification guard** (`guard_provider_profile_admin_fields`):
  a provider updating their own profile cannot change
  `verification_status`/`verification_date`/`rating`/`review_count` — only an
  admin (`is_admin()`) or the trusted rating-recalculation cascade can.
- **Review field ownership** (`guard_review_field_ownership`): a provider
  responding to a review may only set `provider_response`; a customer
  editing their own review may change `rating`/`comment` but not
  `provider_response`. RLS alone permits either participant to update the
  row at all — this trigger is what keeps them to their own column.

## Local development

Running these migrations locally requires either:

1. `supabase start` (Docker-based local Postgres+Auth+Storage stack), or
2. A real Supabase project, linked via `npx supabase link`, with migrations
   pushed via `npx supabase db push`.

Neither is set up yet in this environment — see the note in
[LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md).
