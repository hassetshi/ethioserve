import 'package:ethioserve/features/bookings/presentation/booking_providers.dart';
import 'package:ethioserve/features/bookings/presentation/bookings_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_booking_repository.dart';

void main() {
  testWidgets('shows a booking with its provider, service, and status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingRepositoryProvider.overrideWithValue(FakeBookingRepository())],
        child: const MaterialApp(home: BookingsListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Addis Plumbing Experts'), findsOneWidget);
    expect(find.textContaining('Pipe Repair'), findsOneWidget);
    expect(find.text('Requested'), findsOneWidget);
  });
}
