import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../entities/notification_page.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationsReadUsecase {
  MarkNotificationsReadUsecase(this._repository);

  final NotificationRepository _repository;

  Future<NotificationPage> call({int page = 1}) => _repository.markAllAsRead(page: page);
}

final markNotificationsReadUsecaseProvider = Provider<MarkNotificationsReadUsecase>((ref) {
  return MarkNotificationsReadUsecase(ref.watch(notificationRepositoryProvider));
});
