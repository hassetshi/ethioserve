import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../speech/speech_to_text_service.dart';
import '../speech/text_to_speech_service.dart';

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  return const NoopSpeechToTextService();
});

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  return const NoopTextToSpeechService();
});
