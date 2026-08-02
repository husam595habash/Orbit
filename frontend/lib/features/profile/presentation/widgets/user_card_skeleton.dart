import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Placeholder matching [UserCard]'s layout while a user list loads.
class UserCardSkeleton extends StatelessWidget {
  const UserCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 52, height: 52, borderRadius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ShimmerBox(width: 120, height: 14),
                const SizedBox(height: 8),
                const ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerBox(width: 84, height: 34, borderRadius: 10),
        ],
      ),
    );
  }
}
