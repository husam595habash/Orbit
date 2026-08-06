import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_model.dart';
import '../../data/services/notification_socket_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notifications_read_usecase.dart';
import 'notification_socket_provider.dart';

class NotificationListState {
  const NotificationListState({
    required this.notifications,
    required this.currentPage,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final List<AppNotification> notifications;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  NotificationListState copyWith({
    List<AppNotification>? notifications,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationListViewModel extends AsyncNotifier<NotificationListState> {
  @override
  Future<NotificationListState> build() async {
    ref.listen<AsyncValue<NotificationSocketService>>(notificationSocketServiceProvider, (
      previous,
      next,
    ) {
      next.whenData((service) {
        service.incomingNotifications.listen(_handleIncoming);
      });
    }, fireImmediately: true);

    return _fetchFirstPage();
  }

  Future<NotificationListState> _fetchFirstPage() async {
    final page = await ref.read(getNotificationsUsecaseProvider)(page: 1);
    return NotificationListState(
      notifications: page.notifications,
      currentPage: page.currentPage,
      hasMore: page.hasMore,
      isLoadingMore: false,
    );
  }

  void _handleIncoming(Map<String, dynamic> data) {
    final current = state.valueOrNull;
    if (current == null) return;
    final notification = NotificationModel.fromSocketJson(data);
    state = AsyncValue.data(
      current.copyWith(notifications: [notification, ...current.notifications]),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final page = await ref.read(getNotificationsUsecaseProvider)(page: current.currentPage + 1);

    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(
        notifications: [...latest.notifications, ...page.notifications],
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null || current.notifications.every((n) => n.isRead)) return;

    await ref.read(markNotificationsReadUsecaseProvider)();
    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(
        notifications: [
          for (final n in latest.notifications)
            AppNotification(
              id: n.id,
              details: n.details,
              recipientId: n.recipientId,
              actorId: n.actorId,
              actorName: n.actorName,
              actorImageUrl: n.actorImageUrl,
              isRead: true,
              createdAt: n.createdAt,
            ),
        ],
      ),
    );
  }
}

final notificationListViewModelProvider =
    AsyncNotifierProvider<NotificationListViewModel, NotificationListState>(
  NotificationListViewModel.new,
);
