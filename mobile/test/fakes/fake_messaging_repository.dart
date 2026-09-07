import 'dart:async';
import 'dart:typed_data';

import 'package:ethioserve/features/messaging/domain/chat_message.dart';
import 'package:ethioserve/features/messaging/domain/messaging_repository.dart';

class FakeMessagingRepository implements MessagingRepository {
  final _controller = StreamController<List<ChatMessage>>.broadcast();
  final List<ChatMessage> _messages = [];

  void _emit() => _controller.add(List.unmodifiable(_messages));

  @override
  Stream<List<ChatMessage>> watchMessages(String bookingId) {
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<void> sendTextMessage({
    required String bookingId,
    required String receiverId,
    required String message,
  }) async {
    _messages.add(
      ChatMessage(
        id: 'msg-${_messages.length}',
        bookingId: bookingId,
        senderId: 'me',
        receiverId: receiverId,
        message: message,
        messageType: 'text',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  @override
  Future<void> sendImageMessage({
    required String bookingId,
    required String receiverId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {}

  @override
  Future<void> markAsRead(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final m = _messages[index];
    _messages[index] = ChatMessage(
      id: m.id,
      bookingId: m.bookingId,
      senderId: m.senderId,
      receiverId: m.receiverId,
      message: m.message,
      messageType: m.messageType,
      isRead: true,
      createdAt: m.createdAt,
    );
    _emit();
  }

  @override
  Future<String> getSignedImageUrl(String storagePath) async =>
      'https://example.com/$storagePath';
}
