import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message_page.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remoteDataSource);

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<List<Conversation>> getConversations() => _remoteDataSource.getConversations();

  @override
  Future<MessagePage> getMessages({
    required String userAId,
    required String userBId,
    int page = 0,
  }) async {
    final data = await _remoteDataSource.getMessages(
      userAId: userAId,
      userBId: userBId,
      page: page,
    );
    final messages = (data['messages'] as List)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return MessagePage(
      messages: messages,
      currentPage: data['currentPage'] as int,
      numberOfPages: data['numberOfPages'] as int,
    );
  }

  @override
  Future<void> markAsRead(String senderId) => _remoteDataSource.markAsRead(senderId);
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
});
