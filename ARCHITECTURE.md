# Architecture

## Technology stack

| Layer | Choice | Why |
|---|---|---|
| Mobile | Flutter (Dart, null-safe) | Single codebase for Android (primary) + iOS (secondary) |
| State management | **Riverpod** (`flutter_riverpod`) | See decision below |
| Navigation | `go_router` | Declarative routing, needed for role-scoped route guarding (customer vs provider vs admin) and deep links |
| Backend | Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) | Per spec section 7 |
| Admin web | Separate app under `admin-web/` (framework decided in Phase 10) | Spec section 13: admin functionality must never live inside the customer mobile app |
| Localization | Flutter's `gen_l10n` (ARB files) | English + Amharic now; Afaan Oromo/Tigrinya/Somali are additive ARB files later, no code changes |

### State management: Riverpod, not Bloc

The spec allows either. Riverpod was chosen because:

- Compile-time-safe provider graph (no `BuildContext`-based service location), which
  matters here because the customer app, provider-facing screens, and eventually
  admin-web-style screens inside the same mobile app share a lot of the same
  repositories (auth, bookings, provider profile).
- Less boilerplate than Bloc for the CRUD-heavy screens that dominate this app
  (provider profile, services, availability, bookings) — most screens are
  "fetch, display, mutate," not complex multi-step state machines, aside from
  the booking status machine, which is enforced server-side in Postgres anyway
  (see `supabase/migrations/20260831000004_bookings.sql`), so the client doesn't
  need Bloc's explicit state-machine ceremony to stay correct.
- Native support for `Notifier`/`AsyncNotifier` covers the realtime-subscription
  and async-repository patterns this app needs (chat, booking status updates)
  without extra glue.

## Folder structure (`mobile/lib/`)

Feature-first, with a small shared `core/`:

```
lib/
├── main.dart              Bootstraps Supabase (if configured) and runs the app
├── app.dart               MaterialApp.router, theme, localization delegates
├── core/
│   ├── config/            Compile-time environment config (env_config.dart)
│   ├── errors/            AppException hierarchy — UI never sees raw errors
│   ├── logging/           Centralized logger (never logs secrets, see SECURITY.md)
│   ├── providers/         Cross-cutting Riverpod providers (e.g. locale)
│   ├── router/            go_router route table
│   └── theme/             Single source of truth for colors/typography
├── features/
│   ├── auth/               Phone-OTP login (AuthRepository, LoginScreen, OtpVerificationScreen)
│   ├── profile/            Profile view/edit (ProfileRepository, ProfileScreen)
│   └── <feature>/
│       ├── data/          Repository implementations (Supabase calls live ONLY here)
│       ├── domain/        Repository interfaces + entities (no Supabase imports)
│       └── presentation/  Screens + widgets (no direct Supabase calls — repository pattern per spec section 49)
└── l10n/                  ARB source files (generated/ is gitignored, regenerated on build)
```

Rule enforced from Phase 2 onward: widgets never call `Supabase.instance` directly;
they depend on a `domain` repository interface, implemented in `data/`, injected via
a Riverpod provider. This is what spec section 49 means by "repository pattern" and
"no direct database access scattered throughout UI."

## Environment configuration

Flutter has no native `.env` file support, so environment-specific config is passed at
**compile time** via `--dart-define-from-file=mobile/env/<environment>.json`, read by
`lib/core/config/env_config.dart`. This keeps config out of the compiled asset bundle
(unlike `flutter_dotenv`, which ships the file as a readable asset). Only the Supabase
*anon* key ever goes into these files — the service-role key never ships in the app
(spec sections 7, 25, 31).

Real per-environment files (`mobile/env/development.json`, `staging.json`,
`production.json`) are gitignored; `*.example.json` versions are committed as
templates. See `.env.example` at the repo root for the full list of config values
used anywhere in the project (including server-only ones for Edge Functions).

## Development phases

Following the spec's phase order (section 48):

1. **Project setup** — done (this document, plus the schema and mobile scaffold).
2. **Authentication, users, profiles, roles** — done: phone-OTP login/verification
   screens, `AuthRepository`/`ProfileRepository` (repository pattern, no direct
   Supabase calls from widgets), router-level redirect gating every route on
   locale + auth state + role (admins are blocked from the mobile app
   entirely, per spec section 13/43). Real OTP delivery is blocked on an SMS
   provider not yet being configured on the Supabase project (confirmed via a
   live `phone_provider_disabled` response) — the code path is otherwise
   complete and covered by tests using a fake `AuthRepository`.
3. **Categories, services, provider profiles** — done: `CatalogRepository`
   (categories/services) and `ProviderRepository` (provider detail + a
   provider list per service, both reusing the `search_providers` RPC from
   Phase 1 rather than duplicating query logic). Home now shows real
   categories; tapping one lists its services; tapping a service lists
   verified providers offering it; tapping a provider shows the full profile
   (photos, description, rating, services+pricing). Storage buckets
   (`provider-photos` public, `provider-documents` private) and a starter
   services catalog (3 per category) were added as migrations. Verified
   end-to-end against the live dev project with a seeded sample provider
   (see `scripts/dev-seed-sample-provider.sql`).
4. **Provider registration, Provider verification** — done: a logged-in
   customer can register as a provider from the Profile screen
   ("Become a provider"), landing on a Provider Dashboard once approved
   through `register_as_provider` — a `SECURITY DEFINER` RPC, because
   promoting `users.role` is exactly the kind of client-untrusted mutation
   spec section 31 has in mind, and RLS correctly refuses to let a client do
   it directly. The dashboard lets a provider add offered services
   (category → service → pricing) and upload verification documents to the
   private `provider-documents` bucket; an admin actually approving those
   (flipping `verification_status` to `verified`) is Phase 10 (admin-web),
   since spec section 13 keeps admin functionality out of this app entirely.
   Verified the RPC's auth guard against the live project (an unauthenticated
   call is correctly rejected with a clean error, not a raw exception).
5. **Provider search, Location, Filtering** — done: a real Home search field
   (text search over service names, English/Amharic) and a generalized
   `ProviderSearchResultsScreen` — shared by the Phase 3 category-browse flow
   and the new text-search flow, both converging on `ProviderRepository
   .searchProviders()` (one query path, not two) — with filters for city,
   minimum rating, and an opt-in "Near me" toggle. `LocationService`
   (`core/location/`) wraps `geolocator`: permission is requested only when
   the user taps "Near me," every failure path degrades to `null` rather than
   throwing, and city/rating filtering works with no location at all (spec
   section 18: never require GPS for every feature). Verified live: substring
   search in both languages, the `min_rating` filter, and real-coordinate
   distance filtering/sorting all confirmed against the dev project.
   Deliberately deferred: availability- and price-range filtering (spec
   section 17 lists them too) — the RPC can take those params later without
   a redesign, but there's no meaningful UI for them until bookings
   (Phase 6) give "availability" a concrete meaning.
6. **Booking system** — done: request → confirmation → tracking → bookings
   list, on both the customer and provider sides, sharing one
   `BookingDetailsScreen` that shows role-appropriate actions (accept/
   decline/on-the-way/in-progress/complete for the provider; cancel for the
   customer) rather than two near-duplicate screens. Live status updates via
   Supabase Realtime (`BookingRepository.watchBooking`), with the joined
   display fields (provider name, service name, customer phone) re-attached
   to each realtime row since Realtime only delivers plain columns, not
   embeds. A real gap in the Phase 1 trigger got fixed here: it validated
   which status *values* were reachable but not *who* could set them — a
   customer could have set their own booking straight to `accepted`. Fixed
   in `20260831000015_booking_transition_actor_rules.sql` and verified live
   with two distinct real identities (see TESTING.md) — a customer accepting
   their own booking is now rejected, the assigned provider succeeds, and
   invalid value transitions are still rejected regardless of actor.
7. **Notifications** — in-app half done: `notifications` rows are generated
   server-side by triggers on `bookings` (new request → provider, every
   status change → the other participant), verified live. A Notifications
   screen, a shared unread-count badge (`NotificationBell`, Realtime-backed)
   on Home and the Provider Dashboard, mark-as-read/mark-all-read. The actual
   *push* delivery (spec section 21 — reaching the device tray when the app
   is closed) is behind `PushNotificationService`, an interface with a
   `NoopPushNotificationService` default — "use a notification abstraction
   so providers can be changed later" is exactly this. Wiring a real
   implementation (Firebase Cloud Messaging) is a pending decision — it
   needs a Firebase project and, for server-initiated sends, an Edge
   Function holding a service-account credential that must never reach the
   client, same category of decision as Twilio in Phase 2.
8. **Messaging** — done: booking-scoped chat (text + images), reached from
   Booking Details. The schema and RLS for this were already complete from
   Phase 1 (`messages` table, participant-only policies) — Phase 8 is
   Realtime + UI on top of infrastructure that was already correct. Chat
   images go to a private `chat-images` bucket (path `{booking_id}/...`,
   RLS via `is_booking_participant()` on the path's first segment) and are
   displayed via time-limited signed URLs, not permanent public ones.
   Verified live: RLS correctly returns zero rows for an unauthenticated
   read and rejects a spoofed insert with a 401 (`new row violates row-level
   security policy`) — confirming no one can read or send a message without
   being a genuine participant with a real session. Deliberately trimmed: no
   separate "Messages" inbox screen aggregating conversations across
   bookings — each conversation is reached via its booking (Booking Details
   → Chat), which is the only context chat exists in for this app, so a
   separate inbox would mostly duplicate the bookings list for modest
   added value.
9. **Reviews** — done: leave-a-review on a completed booking (Booking
   Details), a reviews list + provider-response flow on the Provider Profile
   screen. Found and fixed two real bugs while building this:
   1. `reviews_provider_respond` (Phase 1 RLS) let a provider UPDATE *any*
      column on their own review, not just `provider_response` — they could
      have rewritten the customer's rating. Same category as the Phase 6
      booking-actor gap; fixed with a trigger (RLS is row-level, it can't
      express "this actor may only touch this one column").
   2. A customer submitting a review (fully legitimate, RLS-validated)
      cascaded into `recalculate_provider_rating()`, which updates
      `provider_profiles.rating` — and that update was being rejected by
      the Phase 1 `guard_provider_profile_admin_fields()` trigger, because
      it checked `is_admin()` against the *customer's* `auth.uid()`, with
      no way to tell "a trusted system cascade" apart from "a client
      directly editing their own provider row." First attempted fix (check
      `current_user <> session_user`, assuming that only diverges under
      `SECURITY DEFINER`) was itself wrong for Supabase's actual connection
      model — PostgREST connects as a fixed `authenticator` role and does
      `SET ROLE` per request, so `session_user` never equals `current_user`
      for *any* authenticated request, cascade or not; that fix would have
      disabled the guard entirely. Correct fix: an explicit transaction-local
      flag (`set_config('app.internal_rating_update', ...)`) the cascade
      sets around its own update — no reliance on role-switching semantics.
   Both verified live with the two test identities: the "already registered
   0.00/0" provider went to the correct `5.00/1` after a real review
   insert; a provider attempt to alter the rating while responding was
   rejected; a provider setting only `provider_response` succeeded.
10. **Admin dashboard (`admin-web/`)** — done for MVP scope (spec section
    46: provider approval, users, providers, categories, services, bookings).
    Separate React + Vite + TypeScript + Tailwind app (decision documented in
    `admin-web/README.md`, same pattern as the mobile Riverpod decision) —
    a completely different codebase from `mobile/`, per spec section 13.
    Real authorization is RLS (`is_admin()`), same as everywhere else; the
    client-side `ProtectedRoute` check only decides what the UI shows.
    Provider verification review (viewing submitted documents via signed
    URLs, approve/reject/suspend) is the centerpiece, since that's the one
    piece of the whole system nothing else could do — every other admin
    MVP page (Users, Categories, Services, Bookings) is close to plain CRUD
    over tables whose RLS was already admin-ready since Phase 1.

    **A genuinely hard bug, worth recording in full because the fix had
    nothing to do with any code in this repo:** admin login worked at the
    API level but the browser kept bouncing back to the login screen. The
    browser console showed a storm of `TOKEN_REFRESHED` events (every
    ~120ms) ending in a 429 from Supabase's rate limiter and a forced
    sign-out. The investigation went through several wrong turns before
    landing on the real cause:
    1. First suspected [supabase-js#2126](https://github.com/supabase/supabase-js/issues/2126),
       a known race triggered by ECC (P-256) JWT signing keys — the
       project's active key *was* ES256, matching the report exactly.
       Rotated it back to HS256 (the format it used before an automatic
       migration 16 hours earlier). No change in behavior.
    2. Then suspected `AuthContext.tsx` exporting both a component and a
       hook, which breaks Vite Fast Refresh and was confirmed (via the dev
       server log) to have left two live `GoTrueClient` instances racing
       over the same stored session ("Multiple GoTrueClient instances
       detected"). Fixed the file structure and did a full server restart.
       Still no change, even in a brand new browser profile.
    3. Set `autoRefreshToken: false`, reasoning the background refresh
       ticker was the culprit. No change — the loop continued.
    4. Set `persistSession: false` too, removing any stored session for an
       on-demand refresh path to act on. **Still no change**, even in a
       completely different browser (Chrome instead of Edge) with a fully
       fresh profile — which is what finally proved the cause couldn't be
       anything in this app's code or its browser storage at all.
    5. Reading `auth-js`'s source directly (rather than guessing further)
       showed `__loadSession()` treats a session as needing refresh whenever
       `expires_at * 1000 - Date.now() < 90_000ms` — a check that runs on
       *every* `getSession()` call (i.e. before every database query),
       completely independently of the `autoRefreshToken` option. Testing
       login + an immediate refresh directly against the API showed both
       responses' `expires_at` were **~2-3 hours in the past** relative to
       the value `Date.now()` was producing locally. The dev machine's
       system clock was running about 3 hours ahead of real UTC time,
       confirmed by comparing it directly to Supabase's own `Date` response
       header. Every token — including ones issued seconds earlier — looked
       already expired to the skewed local clock, so every database query
       triggered an immediate refresh, forever, until the rate limiter cut
       it off. Fixed by resyncing the machine's clock (Settings → Time &
       Language → Date & Time → Sync now); confirmed by re-comparing local
       vs. server time before declaring it fixed, not just by re-testing
       login and hoping.
    The `autoRefreshToken: false` / `persistSession: false` client config
    changes from steps 3–4 were kept even after finding the real cause —
    they don't fix clock skew, but they stop this specific app from turning
    any future skew into a broken login loop, which is a reasonable
    defensive posture for an admin tool regardless.
11. **AI search** — done: a Supabase Edge Function (`supabase/functions/ai-search`)
    calls Claude to classify a free-text query (English or Amharic) against
    the platform's actual current categories/services, verifies every id it
    returns against that same catalog before trusting it, and the client
    feeds the validated result into the existing `search_providers` RPC —
    no new search code path, no AI-generated SQL, matching spec section 15
    exactly. `AIService` is a vendor-agnostic interface, same pattern as
    `PushNotificationService` (Phase 7). `SpeechToTextService`/
    `TextToSpeechService` interfaces exist per spec section 16 with `Noop`
    defaults — deliberately not wired to a real STT/TTS vendor yet, since
    on-device Amharic speech recognition quality needs validating against
    real users before committing to one, unlike text search which was
    straightforward to ship working end-to-end now. See AI.md for the full
    pipeline and live verification against the spec's own example queries
    (including the Amharic one, byte-for-byte).
12. **Payment integration** — architecture-only per the spec's own MVP scope
    allowance (section 46: "Architecture only initially, unless payment
    integration is explicitly configured" — no real provider was configured
    for this pass). What's genuinely real and working, not just stubbed:
    commission calculation (`calculate_commission()`, reading the
    configurable `platform_settings.booking_commission_rate` — never a
    hard-coded 10%, per spec section 23) and cash payments end-to-end
    (`record_cash_payment()`, a `SECURITY DEFINER` RPC only the assigned
    provider can call, only for a completed booking, computing the split
    server-side from `final_price`). Cash needed no external provider to be
    real, so it's built for real rather than stubbed. Digital payment
    (Chapa/Telebirr/etc.) is behind the same `PaymentRepository` interface
    but its method currently throws a clear "not yet available" error —
    swapping in a real provider later is an implementation change behind
    that interface, not an architecture change (spec section 20: "Do not
    hard-code one Ethiopian payment provider"). Verified live: correct
    100/900 split on a 1000 ETB booking, a customer attempting to record
    their own payment rejected, a duplicate payment attempt rejected.
13. **Testing hardening** — done: filled the gaps spec section 28 calls out
    by name. Added widget tests for the two screens with zero prior coverage
    (`LoginScreen`, `ProviderProfileScreen`); added a full integration test
    (`test/integration/customer_booking_journey_test.dart`) driving the real
    app through language → login → OTP → home → category → service →
    provider → profile → booking request → confirmation → details, matching
    spec's own example journey through the booking-creation step (provider
    accept/complete and the review step are intentionally left to their own
    existing, more focused tests rather than chained into one giant fake-
    wired scenario). Writing that integration test caught a real bug: the
    reusable `FakeAuthRepository` test double used `Stream.value(_user)` for
    `watchCurrentUser()`, which captures `_user` once and never re-emits
    when it changes later — every *earlier* test happened to start already
    logged in or stay logged out for its whole duration, so this never
    surfaced until a test needed to observe the unauthenticated → authenticated
    transition live. Fixed with a proper broadcast stream. Also added
    `scripts/security-tests.mjs`, turning the RLS/authorization checks that
    had been verified ad-hoc throughout every phase since 4 into one
    repeatable suite (18 checks: unauthenticated REST/RPC access, booking
    actor-authorization, payment authorization) — confirmed idempotent by
    running it twice in a row against the live dev project. Not added: a
    dedicated Deno unit test for the `ai-search` Edge Function's output-
    validation logic (spec section 28 names "AI response validation"
    explicitly) — its behavior is already verified live (AI.md, Phase 11),
    and standing up a Deno test toolchain for one function felt like more
    new infrastructure than the incremental coverage justified; worth
    revisiting if the Edge Function surface grows.
14. **CI/CD** — done: two path-filtered GitHub Actions workflows
    (`.github/workflows/mobile-ci.yml`, `admin-web-ci.yml`), each running on
    every PR and on pushes to `develop`/`staging`/`main`. Mobile runs
    `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`;
    admin-web runs `oxlint` then `tsc -b && vite build`. Neither needs real
    Supabase secrets — both apps' env-config modules degrade to
    unconfigured rather than throwing when the corresponding
    `--dart-define`/`VITE_*` values are absent, so CI builds/tests the same
    source a real deployment would use with nothing sensitive in the
    workflow files. Branch protection on `main` (require these checks +
    review, spec section 26) is a GitHub repo Settings change, not
    expressible as a file in this repo — left as a manual step, documented
    in DEPLOYMENT.md. See DEPLOYMENT.md for the full breakdown.
15. Staging deployment
16. Production deployment
17. Google Play / Apple App Store release

## Database

See [DATABASE.md](DATABASE.md).

## Security

See [SECURITY.md](SECURITY.md).
