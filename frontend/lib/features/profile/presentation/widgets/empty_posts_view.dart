import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class EmptyPostsView extends StatelessWidget {
  const EmptyPostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: AppColors.textLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No Posts Yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
