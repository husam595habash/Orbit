import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../domain/entities/app_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return ListTile(
      onTap: onTap,
      tileColor: unread ? AppColors.pink.withValues(alpha: 0.06) : null,
      leading: _Avatar(imageUrl: notification.actorImageUrl),
      title: Text(
        notification.details,
        style: TextStyle(
          color: AppColors.textLight,
          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        timeAgo(notification.createdAt),
        style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5), fontSize: 12),
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 20, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
