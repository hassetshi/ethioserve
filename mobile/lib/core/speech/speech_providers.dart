import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'speech_to_text_service.dart';
import 'speech_to_text_service_impl.dart';

final speechToTextServiceProvider = Provider<SpeechToTextService>((ref) {
  return DeviceSpeechToTextService();
});
