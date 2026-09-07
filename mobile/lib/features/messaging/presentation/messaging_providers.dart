import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_messaging_repository.dart';
import '../domain/chat_message.dart';
import '../domain/messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return SupabaseMessagingRepository(Supabase.instance.client);
});

final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, bookingId) {
      return ref.watch(messagingRepositoryProvider).watchMessages(bookingId);
    });
