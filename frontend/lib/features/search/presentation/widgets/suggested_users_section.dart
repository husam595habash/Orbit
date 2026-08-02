import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../profile/presentation/widgets/user_card.dart';
import '../../../profile/presentation/widgets/user_card_skeleton.dart';

/// Shown when the search field is empty: a "friends of friends" list from
/// the backend's suggestion graph.
class SuggestedUsersSection extends StatelessWidget {
  const SuggestedUsersSection({
    super.key,
    required this.suggested,
    required this.currentUser,
    required this.onOpenProfile,
    required this.onToggleFollow,
  });

  final AsyncValue<List<User>> suggested;
  final User? currentUser;
  final void Function(String userId) onOpenProfile;
  final void Function(String userId) onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return suggested.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
              'No suggestions yet.',
              style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).padding.bottom + 96),
          itemCount: users.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Suggested for you',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textLight),
                ),
              );
            }
            final user = users[index - 1];
            final isFollowing = currentUser != null && user.followers.contains(currentUser!.id);
            final mutualCount = currentUser == null
                ? 0
                : currentUser!.following.toSet().intersection(user.followers.toSet()).length;
            return UserCard(
              user: user,
              isFollowing: isFollowing,
              mutualCount: mutualCount,
              onTap: () => onOpenProfile(user.id),
              onToggleFollow: () => onToggleFollow(user.id),
            );
          },
        );
      },
    );
  }
}
