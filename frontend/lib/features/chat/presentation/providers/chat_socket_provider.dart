import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';
import '../../data/services/chat_socket_service.dart';

/// Connects once the first screen inside the chat feature starts watching
/// it, and disconnects once the last one stops (ChatListPage and any
/// ChatConversationPage pushed on top of it share this single connection).
final chatSocketServiceProvider = FutureProvider.autoDispose<ChatSocketService>((ref) async {
  final token = await ref.read(tokenStorageProvider).readToken();
  final service = ChatSocketService();
  await service.connect(token: token);
  ref.onDispose(service.dispose);
  return service;
});
