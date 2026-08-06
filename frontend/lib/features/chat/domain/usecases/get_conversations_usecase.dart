import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUsecase {
  GetConversationsUsecase(this._repository);

  final ChatRepository _repository;

  Future<List<Conversation>> call() => _repository.getConversations();
}

final getConversationsUsecaseProvider = Provider<GetConversationsUsecase>((ref) {
  return GetConversationsUsecase(ref.watch(chatRepositoryProvider));
});
