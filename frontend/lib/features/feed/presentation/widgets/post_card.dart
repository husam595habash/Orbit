import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/coming_soon.dart';
import '../../domain/entities/post.dart';
import 'post_options_sheet.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final String? currentUserId;
  final VoidCallback onToggleLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final liked = currentUserId != null && post.likedBy(currentUserId!);
    final isOwner = currentUserId != null && currentUserId == post.creatorId;
    final hasImage = post.selectedFile != null && post.selectedFile!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: hasImage
            ? _ImagePost(
                post: post,
                liked: liked,
                isOwner: isOwner,
                onToggleLike: onToggleLike,
                onEdit: onEdit,
                onDelete: onDelete,
              )
            : _TextPost(
                post: post,
                liked: liked,
                isOwner: isOwner,
                onToggleLike: onToggleLike,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
      ),
    );
  }
}

class _ImagePost extends StatelessWidget {
  const _ImagePost({
    required this.post,
    required this.liked,
    required this.isOwner,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final bool liked;
  final bool isOwner;
  final VoidCallback onToggleLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        color: AppColors.surfaceDark,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.selectedFile!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppColors.surfaceDark),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.surfaceDark,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _Scrim(alignment: Alignment.topCenter),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _Scrim(alignment: Alignment.bottomCenter),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _PostHeader(
                  post: post,
                  overlay: true,
                  isOwner: isOwner,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostActions(
                      post: post,
                      liked: liked,
                      onToggleLike: onToggleLike,
                      overlay: true,
                    ),
                    if (post.message.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _Caption(post: post, overlay: true),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextPost extends StatelessWidget {
  const _TextPost({
    required this.post,
    required this.liked,
    required this.isOwner,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final bool liked;
  final bool isOwner;
  final VoidCallback onToggleLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            post: post,
            overlay: false,
            isOwner: isOwner,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          if (post.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: _Caption(post: post, overlay: false),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _PostActions(
              post: post,
              liked: liked,
              onToggleLike: onToggleLike,
              overlay: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final fromTop = alignment == Alignment.topCenter;
    return IgnorePointer(
      child: Container(
        height: fromTop ? 90 : 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.overlay,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final bool overlay;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textColor = overlay ? Colors.white : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Avatar(imageUrl: post.creatorImageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.creatorName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                if (post.creatorUsername.isNotEmpty)
                  Text(
                    '@${post.creatorUsername}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.more_horiz, color: textColor),
            onPressed: () => showPostOptionsSheet(
              context,
              isOwner: isOwner,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.liked,
    required this.onToggleLike,
    required this.overlay,
  });

  final Post post;
  final bool liked;
  final VoidCallback onToggleLike;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final iconColor = overlay ? Colors.white : AppColors.textLight;
    final textColor = overlay ? Colors.white : AppColors.textLight;

    return Row(
      children: [
        _ActionIcon(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          color: liked ? AppColors.pink : iconColor,
          count: post.likes.length,
          textColor: textColor,
          onTap: onToggleLike,
        ),
        const SizedBox(width: 16),
        _ActionIcon(
          icon: Icons.mode_comment_outlined,
          color: iconColor,
          count: null,
          textColor: textColor,
          onTap: () => showComingSoon(context, 'Comments'),
        ),
        const SizedBox(width: 16),
        _ActionIcon(
          icon: Icons.send_outlined,
          color: iconColor,
          count: null,
          textColor: textColor,
          onTap: () => showComingSoon(context, 'Sharing'),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.count,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int? count;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('$count', style: TextStyle(color: textColor, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.post, required this.overlay});

  final Post post;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final baseColor = overlay ? Colors.white : AppColors.textLight;
    final hashtagColor = overlay ? AppColors.orange : AppColors.purple;
    final baseStyle = TextStyle(color: baseColor, fontSize: 13.5, height: 1.35);

    final words = post.message.split(' ');
    final spans = <TextSpan>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      spans.add(TextSpan(
        text: i == words.length - 1 ? word : '$word ',
        style: word.startsWith('#')
            ? baseStyle.copyWith(color: hashtagColor, fontWeight: FontWeight.w600)
            : baseStyle,
      ));
    }

    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 18, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
