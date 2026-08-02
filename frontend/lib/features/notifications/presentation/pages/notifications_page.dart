import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Placeholder Notifications tab. The backend has a notifications service
/// (see services/notification.py) but no frontend feed for it yet.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Text(
          'Notifications are coming soon.',
          style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}
