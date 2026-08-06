import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/chat_list_provider.dart';
import '../widgets/conversation_tile.dart';
import 'chat_conversation_page.dart';
import 'new_message_page.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewMessagePage()),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.read(chatListViewModelProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(chatListViewModelProvider.notifier).refresh(),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                      child: Text(
                        'No messages yet.\nTap the pencil icon to start a conversation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(chatListViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              // Messages is now a persistent tab behind the floating bottom
              // nav bar (see MainShellPage's extendBody), so clear it like
              // the other tabs' lists do.
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 96),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    ref
                        .read(chatListViewModelProvider.notifier)
                        .clearUnread(conversation.partnerId);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatConversationPage(
                          partnerId: conversation.partnerId,
                          partnerName: conversation.partnerName,
                          partnerImageUrl: conversation.partnerImageUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
