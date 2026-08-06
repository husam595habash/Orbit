import '../entities/conversation.dart';
import '../entities/message_page.dart';

abstract class ChatRepository {
  Future<List<Conversation>> getConversations();

  /// Page 0 is the most recent page (backend sorts newest-first internally,
  /// then reverses each page back to chronological order before returning).
  Future<MessagePage> getMessages({
    required String userAId,
    required String userBId,
    int page = 0,
  });

  Future<void> markAsRead(String senderId);
}
