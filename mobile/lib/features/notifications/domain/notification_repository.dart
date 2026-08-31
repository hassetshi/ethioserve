import 'app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getMyNotifications();

  /// Live count of unread notifications, for a badge on Home/Dashboard.
  Stream<int> watchUnreadCount();

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead();
}
