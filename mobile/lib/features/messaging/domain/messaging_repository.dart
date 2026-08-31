import 'dart:typed_data';

import 'chat_message.dart';

abstract class MessagingRepository {
  /// Live message list for [bookingId]. RLS already restricts this to the
  /// booking's two participants — no client-side filtering needed.
  Stream<List<ChatMessage>> watchMessages(String bookingId);

  Future<void> sendTextMessage({
    required String bookingId,
    required String receiverId,
    required String message,
  });

  Future<void> sendImageMessage({
    required String bookingId,
    required String receiverId,
    required Uint8List bytes,
    required String fileExtension,
  });

  Future<void> markAsRead(String messageId);

  /// chat-images is a private bucket, so display URLs must be signed
  /// (time-limited) rather than the permanent public URLs used for
  /// provider-photos.
  Future<String> getSignedImageUrl(String storagePath);
}
