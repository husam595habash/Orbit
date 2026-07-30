import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The centered Orbit logo mark, wordmark, and tagline shown on the login
/// hero. The brand gradient lives on the logo mark only; the wordmark itself
/// is plain white.
class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Image.asset(
            'assets/images/brand icon.png',
            width: 140,
            height: 140,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Orbit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect. Create. Belong.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
