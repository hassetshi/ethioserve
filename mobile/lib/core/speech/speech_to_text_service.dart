/// Vendor-agnostic speech recognition (spec section 16). Initial target is
/// Amharic; the interface itself is language-agnostic so a provider swap
/// never touches call sites.
abstract class SpeechToTextService {
  Future<bool> get isAvailable;

  /// Listens once and returns the recognized text, or `null` if
  /// unavailable/cancelled/no speech detected.
  Future<String?> listen({required String languageCode});
}

/// Default until a real provider (on-device or cloud STT) is wired in.
class NoopSpeechToTextService implements SpeechToTextService {
  const NoopSpeechToTextService();

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<String?> listen({required String languageCode}) async => null;
}
