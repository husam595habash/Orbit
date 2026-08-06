import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.details,
    required super.recipientId,
    required super.actorId,
    required super.actorName,
    required super.actorImageUrl,
    required super.isRead,
    required super.createdAt,
  });

  /// From the REST history endpoint.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return NotificationModel(
      id: json['id'] as String,
      details: json['details'] as String,
      recipientId: json['recipient_id'] as String,
      actorId: json['actor_id'] as String,
      actorName: actor?['name'] as String? ?? '',
      actorImageUrl: actor?['imageUrl'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// From a live WebSocket push — same data, differently shaped (see
  /// NotificationService.SendNotification on the gRPC servicer side):
  /// `is_read` instead of `isRead`, `user: {name, avatar}` instead of
  /// `actor: {name, imageUrl}`.
  factory NotificationModel.fromSocketJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return NotificationModel(
      id: json['id'] as String,
      details: json['details'] as String,
      recipientId: json['recipient_id'] as String,
      actorId: json['actor_id'] as String,
      actorName: user?['name'] as String? ?? '',
      actorImageUrl: user?['avatar'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
