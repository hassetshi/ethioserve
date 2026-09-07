/// Vendor-agnostic push notification interface (spec section 21: "Use a
/// notification abstraction so providers can be changed later"). The app
/// depends only on this; nothing outside a concrete implementation ever
/// imports a vendor SDK (e.g. `firebase_messaging`) directly.
abstract class PushNotificationService {
  /// Requests permission (where the platform requires it) and starts
  /// listening for token refresh / foreground messages. Safe to call once
  /// at app startup regardless of login state.
  Future<void> initialize();

  /// The current device token, or `null` if push isn't available/permitted.
  /// A concrete implementation is responsible for upserting this into
  /// `device_tokens` once a user is logged in.
  Future<String?> getToken();
}

/// Default until a real provider is wired in — every call is a safe no-op,
/// so the rest of the app never has to check "is push configured?" before
/// calling into this interface.
class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => null;
}
