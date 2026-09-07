import 'package:ethioserve/features/notifications/presentation/notification_providers.dart';
import 'package:ethioserve/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_notification_repository.dart';

void main() {
  testWidgets('shows a notification and marks it read on tap', (tester) async {
    final fakeRepo = FakeNotificationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New booking request'), findsOneWidget);
    expect(fakeRepo.notifications.single.isRead, isFalse);

    await tester.tap(find.text('New booking request'));
    await tester.pumpAndSettle();

    expect(fakeRepo.notifications.single.isRead, isTrue);
  });
}
