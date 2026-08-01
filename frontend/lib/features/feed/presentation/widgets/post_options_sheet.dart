import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/coming_soon.dart';

/// The post "..." menu: destructive owner actions, or a report option for
/// other users' posts.
Future<void> showPostOptionsSheet(
  BuildContext context, {
  required bool isOwner,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwner) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit post'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete post', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, onDelete);
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report post'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showComingSoon(context, 'Reporting');
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(BuildContext context, VoidCallback onDelete) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text('Delete post?'),
      content: const Text("This can't be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onDelete();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}
