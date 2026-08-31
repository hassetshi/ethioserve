# Testing

## What exists today (Phase 1)

```powershell
cd mobile
flutter analyze   # static analysis — currently clean
flutter test      # 15 tests passing as of Phase 3
```

- `test/widget_test.dart`: app-shell + router redirect behavior — language
  selection, unauthenticated → login redirect, authenticated → home redirect
  (now also asserting the categories grid renders with real-shaped data).
  Uses `test/fakes/fake_auth_repository.dart` and
  `test/fakes/fake_catalog_repository.dart` (provider overrides in the
  `ProviderScope`) so these never touch the real Supabase client — this is
  the pattern for any widget test that depends on remote data going forward.
- `test/features/auth/phone_number_validator_test.dart`: pure-logic unit tests
  for Ethiopian phone number normalization/validation.
- `test/features/catalog/category_detail_screen_test.dart`: services list
  renders for a given category.

Live OTP delivery is now confirmed working end-to-end (Twilio configured on
the dev Supabase project) — not covered by an automated test (that would need
a real phone to receive the SMS), but verified manually via the
`/auth/v1/otp` endpoint. The Phase 3 browse flow (categories → services →
providers → profile) was verified the same way: direct REST/RPC calls against
the live dev project with a seeded sample provider
(`scripts/dev-seed-sample-provider.sql`), confirming the exact JSON shapes the
Dart parsing code expects.

## Planned (spec section 28), added as each phase lands

- **Unit tests**: business logic, booking state transitions (the Postgres
  trigger in `20260831000004_bookings.sql` is the source of truth; Dart-side
  unit tests cover the repository/UI logic that calls it), pricing, commission
  calculations, AI response validation, auth logic.
- **Widget tests**: login, home, search, booking, provider profile screens.
- **Integration tests**: full customer journey — login → search → provider →
  booking → provider acceptance → completion → review.
- **Security tests**: RLS policy checks, authorization, role separation —
  these are SQL-level tests against the Supabase project (`supabase test db`),
  not Dart tests.
