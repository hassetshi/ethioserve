import 'package:ethioserve/features/notifications/domain/app_notification.dart';
import 'package:ethioserve/features/notifications/domain/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> notifications = [
    AppNotification(
      id: 'n1',
      title: 'New booking request',
      body: 'You have a new booking request.',
      notificationType: 'booking_requested',
      referenceId:
          null, // keeps this fixture from triggering router navigation in tests
      isRead: false,
      createdAt: DateTime(2026, 8, 31),
    ),
  ];

  @override
  Future<List<AppNotification>> getMyNotifications() async => notifications;

  @override
  Stream<int> watchUnreadCount() =>
      Stream.value(notifications.where((n) => !n.isRead).length);

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    final n = notifications[index];
    notifications[index] = AppNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      notificationType: n.notificationType,
      referenceId: n.referenceId,
      isRead: true,
      createdAt: n.createdAt,
    );
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < notifications.length; i++) {
      await markAsRead(notifications[i].id);
    }
  }
}
