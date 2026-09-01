// Integration test: customer login -> search -> provider -> booking (spec
// section 28's example journey), driven through the real app/router with
// fakes standing in for the backend. Provider-side accept/complete and the
// review step are intentionally NOT chained into this same test — they'd
// require simulating a second identity's actions mid-flow, which adds a lot
// of fake-wiring complexity for limited extra confidence given each of
// those steps already has its own dedicated, more focused test
// (booking_details_screen actions, leave_review_section_test). This test's
// job is proving the DISCOVERY -> BOOKING pipeline is wired correctly
// end-to-end through real navigation, not re-proving each screen in isolation.
import 'package:ethioserve/app.dart';
import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/bookings/presentation/booking_providers.dart';
import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/providers/domain/provider_summary.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_booking_repository.dart';
import '../fakes/fake_catalog_repository.dart';
import '../fakes/fake_provider_repository.dart';

void main() {
  testWidgets(
    'customer: language -> login -> OTP -> home -> category -> service -> '
    'provider -> profile -> booking request -> confirmation -> details',
    (tester) async {
      final fakeProviders = FakeProviderRepository(
        searchResults: const [
          ProviderSummary(
            providerId: 'provider-1',
            businessName: 'Addis Plumbing Experts',
            rating: 4.5,
            reviewCount: 10,
            verificationStatus: 'verified',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(),
            ),
            providerRepositoryProvider.overrideWithValue(fakeProviders),
            bookingRepositoryProvider.overrideWithValue(
              FakeBookingRepository(),
            ),
          ],
          child: const EthioServeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Language selection.
      expect(find.text('Choose your language'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Login.
      expect(find.text('Enter your phone number'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '0912345678');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // OTP.
      expect(find.text('Verify your number'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Home, with real categories from the fake catalog.
      expect(find.text('What service do you need?'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      await tester.tap(find.text('Plumbing'));
      await tester.pumpAndSettle();

      // Category detail: services list.
      expect(find.text('Pipe Repair'), findsOneWidget);
      await tester.tap(find.text('Pipe Repair'));
      await tester.pumpAndSettle();

      // Search results: the one verified provider.
      expect(find.text('Addis Plumbing Experts'), findsOneWidget);
      await tester.tap(find.text('Addis Plumbing Experts'));
      await tester.pumpAndSettle();

      // Provider profile.
      expect(
        find.text('Test Provider'),
        findsOneWidget,
      ); // FakeProviderRepository's detail fixture
      await tester.tap(find.text('Book'));
      await tester.pumpAndSettle();

      // Booking request: fill the minimum required fields.
      expect(find.text('Request a booking'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pipe Repair').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Address'),
        'Bole, Addis Ababa',
      );
      await tester.tap(find.text('Submit request'));
      await tester.pumpAndSettle();

      // Confirmation, then through to the booking's own details screen.
      expect(find.text('Request sent!'), findsOneWidget);
      await tester.tap(find.text('View booking'));
      await tester.pumpAndSettle();

      expect(
        find.text('Pipe Repair'),
        findsOneWidget,
      ); // service name on Booking Details
      expect(
        find.textContaining('Addis Plumbing Experts'),
        findsWidgets,
      ); // provider name shown again
    },
  );
}
