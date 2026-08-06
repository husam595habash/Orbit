import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/coming_soon.dart';

/// "Edit Profile" for your own profile (no editor built yet — placeholder),
/// or a real "Follow"/"Following" toggle plus a "Message" button for
/// someone else's.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onToggleFollow,
    required this.onMessage,
  });

  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => showComingSoon(context, 'Editing your profile'),
          child: const Text('Edit Profile'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: isFollowing
              ? OutlinedButton(onPressed: onToggleFollow, child: const Text('Following'))
              : FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
                  onPressed: onToggleFollow,
                  child: const Text('Follow'),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(onPressed: onMessage, child: const Text('Message')),
        ),
      ],
    );
  }
}
