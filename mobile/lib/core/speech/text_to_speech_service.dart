/// Vendor-agnostic speech synthesis (spec section 16), for reading AI
/// search responses/clarification questions aloud in future phases.
abstract class TextToSpeechService {
  Future<void> speak(String text, {required String languageCode});
}

/// Default until a real provider is wired in.
class NoopTextToSpeechService implements TextToSpeechService {
  const NoopTextToSpeechService();

  @override
  Future<void> speak(String text, {required String languageCode}) async {}
}
