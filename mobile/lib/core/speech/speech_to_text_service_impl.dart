import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_to_text_service.dart';

/// Real on-device speech recognition, via the platform's own speech engine
/// (Android SpeechRecognizer / iOS Speech framework). Chosen over a cloud
/// STT provider specifically to avoid adding a new vendor/backend.
class DeviceSpeechToTextService implements SpeechToTextService {
  DeviceSpeechToTextService() : _speech = stt.SpeechToText();

  final stt.SpeechToText _speech;

  @override
  Future<bool> get isAvailable =>
      _speech.isAvailable ? Future.value(true) : _speech.initialize();

  @override
  Future<String?> listen({required String languageCode}) async {
    if (!_speech.isAvailable && !await _speech.initialize()) return null;

    final locales = await _speech.locales();
    final match = _matchLocale(locales, languageCode);
    // Known gap: Amharic ('am') isn't in Android's SpeechRecognizer or
    // iOS's Speech framework locale lists on most devices today. Rather
    // than silently falling back to the device default and mis-recognizing
    // it as English, treat "no matching locale" as unsupported so the UI
    // can tell the user to type instead.
    if (match == null) return null;

    final completer = Completer<String?>();
    var started = false;
    try {
      started = await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: match.localeId,
          listenMode: stt.ListenMode.search,
          partialResults: false,
          listenFor: const Duration(seconds: 15),
        ),
      );
    } on Object {
      started = false;
    }
    if (!started) return null;

    final text = await completer.future.timeout(
      const Duration(seconds: 16),
      onTimeout: () => null,
    );
    await _speech.stop();
    return (text == null || text.trim().isEmpty) ? null : text;
  }

  stt.LocaleName? _matchLocale(
    List<stt.LocaleName> locales,
    String languageCode,
  ) {
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith(
        languageCode.toLowerCase(),
      )) {
        return locale;
      }
    }
    return null;
  }
}
