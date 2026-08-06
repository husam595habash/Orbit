import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../repositories/chat_repository.dart';

class MarkMessagesReadUsecase {
  MarkMessagesReadUsecase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String senderId) => _repository.markAsRead(senderId);
}

final markMessagesReadUsecaseProvider = Provider<MarkMessagesReadUsecase>((ref) {
  return MarkMessagesReadUsecase(ref.watch(chatRepositoryProvider));
});
