import 'app_notification.dart';

class NotificationPage {
  const NotificationPage({
    required this.notifications,
    required this.currentPage,
    required this.numberOfPages,
  });

  final List<AppNotification> notifications;
  final int currentPage;
  final int numberOfPages;

  bool get hasMore => currentPage < numberOfPages;
}
