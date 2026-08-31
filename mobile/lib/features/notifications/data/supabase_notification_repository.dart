import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppAuthException('You need to be logged in.');
    return id;
  }

  @override
  Future<List<AppNotification>> getMyNotifications() async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', _requireUserId)
          .order('created_at', ascending: false)
          .limit(50);
      return rows.map(AppNotification.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyNotifications failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Stream<int> watchUnreadCount() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _requireUserId)
        .map((rows) => rows.where((r) => r['is_read'] == false).length);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('markAsRead failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _requireUserId)
          .eq('is_read', false);
    } on PostgrestException catch (e, st) {
      AppLogger.error('markAllAsRead failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
