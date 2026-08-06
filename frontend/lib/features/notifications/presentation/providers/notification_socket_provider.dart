import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';
import '../../data/services/notification_socket_service.dart';

/// Connects once something starts watching it (the Notifications tab) and
/// disconnects once nothing is watching anymore.
final notificationSocketServiceProvider =
    FutureProvider.autoDispose<NotificationSocketService>((ref) async {
  final token = await ref.read(tokenStorageProvider).readToken();
  final service = NotificationSocketService();
  await service.connect(token: token);
  ref.onDispose(service.dispose);
  return service;
});
