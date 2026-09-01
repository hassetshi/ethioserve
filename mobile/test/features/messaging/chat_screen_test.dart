import 'package:ethioserve/features/auth/domain/app_user.dart';
import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/bookings/presentation/booking_providers.dart';
import 'package:ethioserve/features/messaging/presentation/chat_screen.dart';
import 'package:ethioserve/features/messaging/presentation/messaging_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_booking_repository.dart';
import '../../fakes/fake_messaging_repository.dart';

void main() {
  testWidgets('sending a text message shows it in the thread', (tester) async {
    final fakeAuth = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'customer-1',
        role: UserRole.customer,
        languageCode: 'en',
        isActive: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          bookingRepositoryProvider.overrideWithValue(FakeBookingRepository()),
          messagingRepositoryProvider.overrideWithValue(
            FakeMessagingRepository(),
          ),
        ],
        child: const MaterialApp(home: ChatScreen(bookingId: 'booking-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No messages yet. Say hello!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello, on my way?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Hello, on my way?'), findsOneWidget);
  });
}
