import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/push_notification_service.dart';

/// Overridden with a real implementation once a push provider (e.g.
/// Firebase Cloud Messaging) is configured — see PushNotificationService.
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return const NoopPushNotificationService();
});
