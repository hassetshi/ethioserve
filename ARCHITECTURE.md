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
4. Provider registration, provider verification
5. Provider search, location, filtering
6. Booking system
7. Notifications
8. Messaging
9. Reviews
10. Admin dashboard (`admin-web/`)
11. AI search
12. Payment integration
13. Testing (continuous, but hardened/expanded here)
14. CI/CD
15. Staging deployment
16. Production deployment
17. Google Play / Apple App Store release

## Database

See [DATABASE.md](DATABASE.md).

## Security

See [SECURITY.md](SECURITY.md).
