class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String notificationType;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        notificationType: json['notification_type'] as String,
        referenceId: json['reference_id'] as String?,
        isRead: json['is_read'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
