import 'package:ethioserve/features/bookings/presentation/booking_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/router_test_harness.dart';

void main() {
  Future<GoRouter> pumpConfirmation(WidgetTester tester) => pumpTestRouter(
    tester,
    initialLocation: '/placeholder',
    routes: [
      GoRoute(
        path: '/placeholder',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/bookings/b1/confirmation'),
            child: const Text('placeholder'),
          ),
        ),
      ),
      GoRoute(
        path: '/bookings/:bookingId/confirmation',
        builder: (_, state) => BookingConfirmationScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/bookings/:bookingId',
        builder: (_, state) =>
            Text('booking-details-${state.pathParameters['bookingId']}'),
      ),
      GoRoute(path: '/home', builder: (_, _) => const Text('home')),
    ],
  );

  testWidgets('shows a back arrow', (tester) async {
    await pumpConfirmation(tester);
    await tester.tap(find.text('placeholder'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('"View booking" preserves history', (tester) async {
    final router = await pumpConfirmation(tester);
    await tester.tap(find.text('placeholder'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View booking'));
    await tester.pumpAndSettle();
    expect(find.text('booking-details-b1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);
  });

  testWidgets('"Back to home" preserves history', (tester) async {
    final router = await pumpConfirmation(tester);
    await tester.tap(find.text('placeholder'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(BookingConfirmationScreen), findsOneWidget);
  });
}
