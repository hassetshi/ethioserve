import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/app_notification.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(myNotificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final AppNotification notification = notifications[index];
              return ListTile(
                tileColor: notification.isRead
                    ? null
                    : Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                title: Text(notification.title),
                subtitle: Text(notification.body),
                onTap: () async {
                  if (!notification.isRead) {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(notification.id);
                    ref.invalidate(myNotificationsProvider);
                  }
                  if (notification.notificationType == 'booking_requested' ||
                      notification.notificationType ==
                          'booking_status_changed') {
                    if (context.mounted && notification.referenceId != null) {
                      context.push('/bookings/${notification.referenceId}');
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
