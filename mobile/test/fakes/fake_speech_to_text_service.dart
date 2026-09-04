import 'package:ethioserve/core/speech/speech_to_text_service.dart';

class FakeSpeechToTextService implements SpeechToTextService {
  FakeSpeechToTextService({this.available = true, this.result});

  bool available;

  /// The text `listen` resolves to; `null` simulates unavailable/cancelled/
  /// unsupported-language.
  String? result;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<String?> listen({required String languageCode}) async => result;
}
