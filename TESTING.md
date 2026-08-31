# Testing

## What exists today (Phase 1)

```powershell
cd mobile
flutter analyze   # static analysis — currently clean
flutter test      # unit + widget tests — currently 2 passing (app boot, language → home nav)
```

`test/widget_test.dart` covers the Phase 1 app shell: it boots to language
selection, and selecting a language navigates to home with the right localized
text. This is the pattern for widget tests going forward — pump `EthioServeApp`
inside a `ProviderScope`, override providers as needed for the scenario.

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
