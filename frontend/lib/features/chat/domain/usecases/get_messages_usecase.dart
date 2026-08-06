import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../entities/message_page.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUsecase {
  GetMessagesUsecase(this._repository);

  final ChatRepository _repository;

  Future<MessagePage> call({
    required String userAId,
    required String userBId,
    int page = 0,
  }) {
    return _repository.getMessages(userAId: userAId, userBId: userBId, page: page);
  }
}

final getMessagesUsecaseProvider = Provider<GetMessagesUsecase>((ref) {
  return GetMessagesUsecase(ref.watch(chatRepositoryProvider));
});
