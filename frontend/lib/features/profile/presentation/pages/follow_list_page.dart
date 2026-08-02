import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/follow_list_provider.dart';
import '../widgets/user_card.dart';
import '../widgets/user_card_skeleton.dart';
import 'profile_page.dart';

class FollowListPage extends ConsumerWidget {
  const FollowListPage({super.key, required this.userId, required this.kind});

  final String userId;
  final FollowListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (userId, kind);
    final state = ref.watch(followListViewModelProvider(args));
    final currentUser = ref.watch(authViewModelProvider).valueOrNull;
    final title = kind == FollowListKind.followers ? 'Followers' : 'Following';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: state.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => const UserCardSkeleton(),
        ),
        error: (error, _) => Center(
          child: Text('$error', style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7))),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                kind == FollowListKind.followers ? 'No followers yet.' : 'Not following anyone yet.',
                style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              final isFollowing = currentUser != null && user.followers.contains(currentUser.id);
              final mutualCount = currentUser == null
                  ? 0
                  : currentUser.following.toSet().intersection(user.followers.toSet()).length;
              return UserCard(
                user: user,
                isFollowing: isFollowing,
                mutualCount: mutualCount,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfilePage(userId: user.id)),
                ),
                onToggleFollow: () =>
                    ref.read(followListViewModelProvider(args).notifier).toggleFollow(user.id),
              );
            },
          );
        },
      ),
    );
  }
}
