import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Posts / Followers / Following counts, centered and evenly spaced. The
/// latter two open the corresponding list; Posts is just a static count
/// (the grid right below is already the "posts" affordance).
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  final int postsCount;
  final int followersCount;
  final int followingCount;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(count: postsCount, label: 'Posts'),
        _Stat(count: followersCount, label: 'Followers', onTap: onTapFollowers),
        _Stat(count: followingCount, label: 'Following', onTap: onTapFollowing),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.count, required this.label, this.onTap});

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCount(count),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
