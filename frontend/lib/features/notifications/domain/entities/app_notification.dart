// Named AppNotification, not Notification — Flutter's widgets library
// already owns that name (the ScrollNotification base class).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.details,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    required this.actorImageUrl,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String details;
  final String recipientId;
  final String actorId;
  final String actorName;
  final String actorImageUrl;
  final bool isRead;
  final DateTime createdAt;
}
