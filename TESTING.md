# Testing

## What exists today (Phase 1)

```powershell
cd mobile
flutter analyze   # static analysis — currently clean
flutter test      # 14 tests passing as of Phase 2
```

- `test/widget_test.dart`: app-shell + router redirect behavior — language
  selection, unauthenticated → login redirect, authenticated → home redirect.
  Uses `test/fakes/fake_auth_repository.dart` (overrides `authRepositoryProvider`
  in the `ProviderScope`) so these never touch the real Supabase client — this
  is the pattern for any widget test that depends on auth state going forward.
- `test/features/auth/phone_number_validator_test.dart`: pure-logic unit tests
  for Ethiopian phone number normalization/validation.

Live OTP delivery (actually receiving an SMS) isn't covered by an automated
test — it requires a real SMS provider on the Supabase project, which isn't
configured yet. Verified manually instead: a direct call to the Supabase
`/auth/v1/otp` endpoint against the live dev project returns
`phone_provider_disabled`, confirming the app's error-mapping path (generic
message to the user, detail to `AppLogger`) is exercised correctly today.

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
