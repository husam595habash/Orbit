import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/notification_list_provider.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const _loadMoreThreshold = 300.0;

  final _scrollController = ScrollController();
  bool _hasMarkedRead = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(notificationListViewModelProvider.notifier).loadMore();
    }
  }

  void _openActorProfile(String actorId) {
    // If this profile was already viewed earlier in the session (e.g.
    // before they followed you), that provider is cached and won't refetch
    // on its own — force a fresh copy so the follow-back state is correct.
    ref.invalidate(profileViewModelProvider(actorId));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfilePage(userId: actorId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListViewModelProvider);

    // Mark everything read once the first page has actually loaded — the
    // backend only supports marking all of them at once, so there's no
    // finer-grained "mark this one read" to do instead. Guarded by the flag
    // so it fires exactly once per page visit, not on every rebuild.
    if (!_hasMarkedRead && state.hasValue) {
      _hasMarkedRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationListViewModelProvider.notifier).markAllAsRead();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => ref.read(notificationListViewModelProvider.notifier).markAllAsRead(),
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
                  onPressed: () => ref.read(notificationListViewModelProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (notificationState) {
          final notifications = notificationState.notifications;
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(notificationListViewModelProvider.notifier).refresh(),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationListViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: notifications.length + (notificationState.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final notification = notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () => _openActorProfile(notification.actorId),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
