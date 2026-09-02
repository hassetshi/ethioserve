import 'package:ethioserve/features/payments/presentation/payment_providers.dart';
import 'package:ethioserve/features/payments/presentation/payment_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_payment_repository.dart';

void main() {
  testWidgets(
    'provider can record a cash payment and sees the commission split',
    (tester) async {
      final fakeRepo = FakePaymentRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [paymentRepositoryProvider.overrideWithValue(fakeRepo)],
          child: const MaterialApp(
            home: Scaffold(
              body: PaymentSection(
                bookingId: 'booking-1',
                isProviderView: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark as paid (cash)'), findsOneWidget);

      await tester.tap(find.text('Mark as paid (cash)'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('1000 USD (cash) — completed'),
        findsOneWidget,
      );
      expect(find.textContaining('You receive: 900 USD'), findsOneWidget);
    },
  );

  testWidgets('customer sees a read-only pending message, no action button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PaymentSection(bookingId: 'booking-1', isProviderView: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment pending.'), findsOneWidget);
    expect(find.text('Mark as paid (cash)'), findsNothing);
  });
}
