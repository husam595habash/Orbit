import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';

/// A tappable row: avatar, name/username/(bio or mutual-followers), and a
/// Follow button that alone intercepts taps — the rest of the card opens
/// the profile.
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    required this.isFollowing,
    required this.mutualCount,
    required this.onTap,
    required this.onToggleFollow,
  });

  final User user;
  final bool isFollowing;
  final int mutualCount;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstname} ${user.lastname}'.trim();
    final subtitle = user.bio.isNotEmpty
        ? user.bio
        : (mutualCount > 0
            ? '$mutualCount mutual follower${mutualCount == 1 ? '' : 's'}'
            : null);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _Avatar(imageUrl: user.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textLight.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _FollowButton(isFollowing: isFollowing, onTap: onToggleFollow),
            ],
          ),
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
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 24, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowing, required this.onTap});

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        key: ValueKey(isFollowing),
        height: 34,
        child: isFollowing
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Following', style: TextStyle(fontSize: 13)),
              )
            : FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Follow', style: TextStyle(fontSize: 13)),
              ),
      ),
    );
  }
}
