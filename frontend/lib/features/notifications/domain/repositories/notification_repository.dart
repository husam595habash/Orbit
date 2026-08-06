import '../entities/notification_page.dart';

abstract class NotificationRepository {
  Future<NotificationPage> getNotifications({int page = 1});

  /// The backend only supports marking every notification read at once, not
  /// per-notification (see NotificationService.mark_notifications_as_read).
  Future<NotificationPage> markAllAsRead({int page = 1});
}
