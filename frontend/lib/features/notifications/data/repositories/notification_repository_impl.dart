import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_page.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<NotificationPage> getNotifications({int page = 1}) async {
    final data = await _remoteDataSource.getNotifications(page: page);
    return _toPage(data);
  }

  @override
  Future<NotificationPage> markAllAsRead({int page = 1}) async {
    final data = await _remoteDataSource.markAllAsRead(page: page);
    return _toPage(data);
  }

  NotificationPage _toPage(Map<String, dynamic> data) {
    final notifications = (data['notifications'] as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return NotificationPage(
      notifications: notifications,
      currentPage: data['currentPage'] as int,
      numberOfPages: data['numberOfPages'] as int,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider));
});
