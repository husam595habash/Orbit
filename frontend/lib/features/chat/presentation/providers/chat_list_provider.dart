import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/chat_socket_service.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import 'chat_socket_provider.dart';

class ChatListViewModel extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    ref.listen<AsyncValue<ChatSocketService>>(chatSocketServiceProvider, (previous, next) {
      next.whenData((service) {
        service.incomingMessages.listen(_handleIncomingMessage);
      });
    }, fireImmediately: true);

    return ref.read(getConversationsUsecaseProvider)();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final current = state.valueOrNull;
    if (current == null) return;

    final myId = ref.read(authViewModelProvider).valueOrNull?.id;
    if (myId == null) return;

    final senderId = data['sender'] as String;
    final receiverId = data['receiver'] as String;
    // The socket only pushes incoming messages to their receiver, never
    // echoes a message back to its own sender — so a message I sent is
    // bumped via bumpForSentMessage() instead, called from sendMessage().
    if (receiverId != myId) return;

    final index = current.indexWhere((c) => c.partnerId == senderId);
    if (index == -1) {
      // A thread we don't have loaded yet — refetch properly instead of
      // guessing at the partner's display info from a bare id.
      refresh();
      return;
    }

    final existing = current[index];
    final bumped = Conversation(
      partnerId: existing.partnerId,
      partnerName: existing.partnerName,
      partnerUsername: existing.partnerUsername,
      partnerImageUrl: existing.partnerImageUrl,
      lastMessage: data['content'] as String,
      lastMessageAt: DateTime.now(),
      unreadCount: existing.unreadCount + 1,
    );
    state = AsyncValue.data([bumped, ...current.where((c) => c.partnerId != senderId)]);
  }

  /// Called right after we send a message, so the inbox row for that
  /// partner moves to the top and shows the new preview immediately,
  /// instead of only updating once the recipient's socket echo (which
  /// never reaches us — we're the sender, not the receiver) or the next
  /// full refresh happens.
  void bumpForSentMessage(String partnerId, String content) {
    final current = state.valueOrNull;
    if (current == null) return;

    final index = current.indexWhere((c) => c.partnerId == partnerId);
    if (index == -1) {
      // A thread we don't have loaded yet — refetch properly instead of
      // guessing at the partner's display info from a bare id.
      refresh();
      return;
    }

    final existing = current[index];
    final bumped = Conversation(
      partnerId: existing.partnerId,
      partnerName: existing.partnerName,
      partnerUsername: existing.partnerUsername,
      partnerImageUrl: existing.partnerImageUrl,
      lastMessage: content,
      lastMessageAt: DateTime.now(),
      unreadCount: existing.unreadCount,
    );
    state = AsyncValue.data([bumped, ...current.where((c) => c.partnerId != partnerId)]);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(getConversationsUsecaseProvider)());
  }

  /// Called when a conversation is opened, so its unread badge clears
  /// immediately instead of waiting for the next full refresh.
  void clearUnread(String partnerId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final c in current)
        if (c.partnerId == partnerId)
          Conversation(
            partnerId: c.partnerId,
            partnerName: c.partnerName,
            partnerUsername: c.partnerUsername,
            partnerImageUrl: c.partnerImageUrl,
            lastMessage: c.lastMessage,
            lastMessageAt: c.lastMessageAt,
            unreadCount: 0,
          )
        else
          c,
    ]);
  }
}

final chatListViewModelProvider = AsyncNotifierProvider<ChatListViewModel, List<Conversation>>(
  ChatListViewModel.new,
);
