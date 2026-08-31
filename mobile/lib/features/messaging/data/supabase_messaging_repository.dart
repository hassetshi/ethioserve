import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/chat_message.dart';
import '../domain/messaging_repository.dart';

class SupabaseMessagingRepository implements MessagingRepository {
  SupabaseMessagingRepository(this._client);

  final SupabaseClient _client;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppAuthException('You need to be logged in.');
    return id;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String bookingId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at')
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  @override
  Future<void> sendTextMessage({
    required String bookingId,
    required String receiverId,
    required String message,
  }) async {
    try {
      await _client.from('messages').insert({
        'booking_id': bookingId,
        'sender_id': _requireUserId,
        'receiver_id': receiverId,
        'message': message,
        'message_type': 'text',
      });
    } on PostgrestException catch (e, st) {
      AppLogger.error('sendTextMessage failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<void> sendImageMessage({
    required String bookingId,
    required String receiverId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path = '$bookingId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    try {
      await _client.storage.from('chat-images').uploadBinary(path, bytes);
      await _client.from('messages').insert({
        'booking_id': bookingId,
        'sender_id': _requireUserId,
        'receiver_id': receiverId,
        'message': path,
        'message_type': 'image',
      });
    } on StorageException catch (e, st) {
      AppLogger.error('sendImageMessage (storage) failed', error: e, stackTrace: st);
      throw const NetworkException();
    } on PostgrestException catch (e, st) {
      AppLogger.error('sendImageMessage (db) failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<void> markAsRead(String messageId) async {
    try {
      await _client.from('messages').update({'is_read': true}).eq('id', messageId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('markAsRead failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<String> getSignedImageUrl(String storagePath) async {
    try {
      return await _client.storage.from('chat-images').createSignedUrl(storagePath, 3600);
    } on StorageException catch (e, st) {
      AppLogger.error('getSignedImageUrl failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
