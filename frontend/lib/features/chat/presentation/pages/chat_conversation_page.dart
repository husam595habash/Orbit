import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_conversation_provider.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  const ChatConversationPage({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerImageUrl,
  });

  final String partnerId;
  final String partnerName;
  final String partnerImageUrl;

  @override
  ConsumerState<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  static const _loadMoreThreshold = 200.0;

  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  String? _newestMessageId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _loadMoreThreshold) {
      ref.read(chatConversationViewModelProvider(widget.partnerId).notifier).loadOlder();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatConversationViewModelProvider(widget.partnerId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatConversationViewModelProvider(widget.partnerId));
    final myId = ref.watch(authViewModelProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _Avatar(imageUrl: widget.partnerImageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.partnerName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('$error', style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7))),
              ),
              data: (conversation) {
                if (conversation.messages.isNotEmpty) {
                  final newestId = conversation.messages.last.id;
                  // Only auto-scroll when a message actually landed at the
                  // end (a send/receive) — not when loadOlder() prepends
                  // older history while the user is scrolled up reading it.
                  if (newestId != _newestMessageId) {
                    _newestMessageId = newestId;
                    _scrollToBottom();
                  }
                }
                if (conversation.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello to ${widget.partnerName}.',
                      style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: conversation.messages.length + (conversation.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (conversation.isLoadingMore && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final messageIndex = conversation.isLoadingMore ? index - 1 : index;
                    final message = conversation.messages[messageIndex];
                    return _MessageBubble(message: message, isMine: message.senderId == myId);
                  },
                );
              },
            ),
          ),
          _Composer(controller: _textController, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.pink : AppColors.surfaceDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Message...'),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.pink),
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 16, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
