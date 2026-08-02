import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import 'profile_action_button.dart';
import 'profile_stats_row.dart';

/// Avatar, name/username/bio, stats row, and the edit/follow action button.
/// Fades in once the profile data is available.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.postsCount,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  final User user;
  final int postsCount;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstname} ${user.lastname}'.trim();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Avatar(imageUrl: user.imageUrl),
                const SizedBox(width: 24),
                Expanded(
                  child: ProfileStatsRow(
                    postsCount: postsCount,
                    followersCount: user.followers.length,
                    followingCount: user.following.length,
                    onTapFollowers: onTapFollowers,
                    onTapFollowing: onTapFollowing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fullName.isNotEmpty)
              Text(
                fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textLight,
                ),
              ),
            Text(
              '@${user.username}',
              style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.7)),
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                user.bio,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textLight, height: 1.35),
              ),
            ],
            const SizedBox(height: 16),
            ProfileActionButton(
              isOwnProfile: isOwnProfile,
              isFollowing: isFollowing,
              onToggleFollow: onToggleFollow,
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
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 40, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
