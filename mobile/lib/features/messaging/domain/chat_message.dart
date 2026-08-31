class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.receiverId,
    this.message,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String receiverId;
  final String? message;
  final String messageType; // 'text' | 'image'
  final bool isRead;
  final DateTime createdAt;

  bool get isImage => messageType == 'image';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        senderId: json['sender_id'] as String,
        receiverId: json['receiver_id'] as String,
        message: json['message'] as String?,
        messageType: json['message_type'] as String,
        isRead: json['is_read'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
