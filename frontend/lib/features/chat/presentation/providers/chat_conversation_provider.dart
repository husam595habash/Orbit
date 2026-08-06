import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/message_model.dart';
import '../../data/services/chat_socket_service.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/mark_messages_read_usecase.dart';
import 'chat_socket_provider.dart';

class ConversationState {
  const ConversationState({
    required this.messages,
    required this.currentPage,
    required this.hasMore,
    required this.isLoadingMore,
  });

  /// Chronological order (oldest first).
  final List<Message> messages;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  ConversationState copyWith({
    List<Message>? messages,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// One thread, keyed by the other participant's user id.
class ChatConversationViewModel extends FamilyAsyncNotifier<ConversationState, String> {
  @override
  Future<ConversationState> build(String partnerId) async {
    ref.listen<AsyncValue<ChatSocketService>>(chatSocketServiceProvider, (previous, next) {
      next.whenData((service) {
        service.incomingMessages.listen(_handleIncomingMessage);
      });
    }, fireImmediately: true);

    final myId = ref.read(authViewModelProvider).valueOrNull!.id;
    final page = await ref.read(getMessagesUsecaseProvider)(userAId: myId, userBId: partnerId);
    // Fire-and-forget: we're viewing the thread now, so its unread state is stale.
    ref.read(markMessagesReadUsecaseProvider)(partnerId);

    return ConversationState(
      messages: page.messages,
      currentPage: page.currentPage,
      hasMore: page.hasMore,
      isLoadingMore: false,
    );
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final current = state.valueOrNull;
    if (current == null) return;

    final myId = ref.read(authViewModelProvider).valueOrNull?.id;
    if (myId == null) return;

    final senderId = data['sender'] as String;
    final receiverId = data['receiver'] as String;
    final belongsToThisThread =
        (senderId == arg && receiverId == myId) || (senderId == myId && receiverId == arg);
    if (!belongsToThisThread) return;

    state = AsyncValue.data(
      current.copyWith(messages: [...current.messages, MessageModel.fromSocketJson(data)]),
    );

    if (senderId == arg) {
      ref.read(markMessagesReadUsecaseProvider)(arg);
    }
  }

  Future<void> loadOlder() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final myId = ref.read(authViewModelProvider).valueOrNull!.id;
    final page = await ref.read(getMessagesUsecaseProvider)(
      userAId: myId,
      userBId: arg,
      page: current.currentPage + 1,
    );

    final latest = state.valueOrNull ?? current;
    state = AsyncValue.data(
      latest.copyWith(
        messages: [...page.messages, ...latest.messages],
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> sendMessage(String content) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final myId = ref.read(authViewModelProvider).valueOrNull!.id;

    // The backend never echoes a sent message back to the sender's own
    // socket, only pushes it to the receiver — so the sender has to add
    // their own local copy to see it appear.
    final optimistic = Message(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderId: myId,
      receiverId: arg,
      content: content,
      sentAt: DateTime.now(),
    );
    state = AsyncValue.data(current.copyWith(messages: [...current.messages, optimistic]));

    final socket = await ref.read(chatSocketServiceProvider.future);
    socket.send(receiverId: arg, content: content);
  }
}

final chatConversationViewModelProvider =
    AsyncNotifierProvider.family<ChatConversationViewModel, ConversationState, String>(
  ChatConversationViewModel.new,
);
