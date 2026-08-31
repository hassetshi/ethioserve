# Testing

## What exists today (Phase 1)

```powershell
cd mobile
flutter analyze   # static analysis — currently clean
flutter test      # 27 tests passing as of Phase 6
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

Phase 4's `register_as_provider` RPC has its auth guard verified live
(an unauthenticated call correctly returns a clean `P0001` error, not a raw
exception) — the full happy path (an actual customer registering and getting
promoted to provider) needs a real authenticated session, which needs a real
phone completing OTP login; exercise it by running the app once Android/web
is available to click through, rather than via API calls.

Phase 5's search was verified live end-to-end: English- and Amharic-substring
service search, the `min_rating` filter (confirmed it both excludes and
includes the seeded provider depending on threshold), and real-coordinate
geospatial filtering (a nearby point returns `distance_km: 0`; a distant
point with a small radius correctly returns zero results). `LocationService`'s
permission-request/denial handling isn't covered by an automated test (needs
a real device/emulator location prompt) — it's structured so every failure
path returns `null` rather than throwing, which the UI already handles
(falls back to city/rating filtering only).

Phase 6's booking actor-authorization rules got the most thorough live
verification yet, because getting this wrong would be a real security bug:
using a second real test identity (`scripts/dev-seed-second-test-user.sql`,
a customer, alongside the Phase 3 seed provider), verified directly against
the live database with the session GUC that Supabase's `auth.uid()` reads
(`set local request.jwt.claim.sub = '<uuid>'`):
- a customer accepting their own booking → correctly rejected
- the assigned provider accepting it → succeeds
- the customer cancelling an accepted booking → succeeds
- an invalid value transition (`cancelled → completed`) → still rejected
  regardless of actor
- `booking_status_history` correctly attributes each transition to the
  right `changed_by`

The join queries the Dart repository relies on (`provider_profiles`,
`services`, `users!bookings_customer_id_fkey` embeds) were verified via an
equivalent direct SQL join, confirming the exact shape `Booking.fromJson`
expects. Full authenticated REST-level testing (two real users actually
logged in via the app, one creating a booking and the other accepting it)
still needs real app usage to exercise, same caveat as Phases 4-5.

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
