import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../entities/notification_page.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUsecase {
  GetNotificationsUsecase(this._repository);

  final NotificationRepository _repository;

  Future<NotificationPage> call({int page = 1}) => _repository.getNotifications(page: page);
}

final getNotificationsUsecaseProvider = Provider<GetNotificationsUsecase>((ref) {
  return GetNotificationsUsecase(ref.watch(notificationRepositoryProvider));
});
