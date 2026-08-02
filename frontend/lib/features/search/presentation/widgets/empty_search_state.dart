import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.textLight.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight),
          ),
          const SizedBox(height: 6),
          Text(
            'No results for "$query". Try a different name or username.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
