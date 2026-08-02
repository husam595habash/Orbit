import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../feed/domain/entities/post.dart';

/// Square-thumbnail grid, exactly 3 per row, small gaps. Each tile is
/// Hero-tagged so tapping it flies into the full-screen viewer.
class PostsGrid extends StatelessWidget {
  const PostsGrid({super.key, required this.posts, required this.onTapPost});

  final List<Post> posts;
  final void Function(int index) onTapPost;

  static const _crossAxisCount = 3;
  static const _spacing = 2.0;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(_spacing),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = posts[index];
            return _PostTile(post: post, onTap: () => onTapPost(index));
          },
          childCount: posts.length,
        ),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = post.selectedFile != null && post.selectedFile!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'post-${post.id}',
        child: hasImage
            ? Image.network(
                post.selectedFile!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppColors.surfaceDark),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: AppColors.surfaceDark);
                },
              )
            : Container(
                color: AppColors.surfaceDark,
                padding: const EdgeInsets.all(10),
                alignment: Alignment.center,
                child: Text(
                  post.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ),
      ),
    );
  }
}
