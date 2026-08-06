import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/coming_soon.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/presentation/widgets/post_options_sheet.dart';

/// Full-screen, vertically-paged post viewer — tap a grid tile and land on
/// it directly, then keep scrolling through the rest of the list. The image
/// Hero-matches the tapped grid tile for a shared-element transition in.
class PostViewerPage extends StatefulWidget {
  const PostViewerPage({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Post> posts;
  final int initialIndex;
  final String? currentUserId;
  final void Function(String postId) onToggleLike;
  final void Function(Post post) onEdit;
  final Future<void> Function(Post post) onDelete;

  @override
  State<PostViewerPage> createState() => _PostViewerPageState();
}

class _PostViewerPageState extends State<PostViewerPage> {
  late final _pageController = PageController(initialPage: widget.initialIndex);
  // A local, optimistically-updated copy: widget.posts is a snapshot taken
  // when this page was pushed, and nothing here watches the provider it
  // came from, so without this the like button wouldn't visibly respond
  // until the whole page was torn down and rebuilt.
  late final _posts = List.of(widget.posts);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleToggleLike(Post post) {
    final userId = widget.currentUserId;
    if (userId == null) return;

    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final current = _posts[index];
    final liked = current.likedBy(userId);
    final likes = liked
        ? current.likes.where((id) => id != userId).toList()
        : [...current.likes, userId];

    setState(() {
      _posts[index] = Post(
        id: current.id,
        title: current.title,
        message: current.message,
        creatorId: current.creatorId,
        creatorName: current.creatorName,
        creatorUsername: current.creatorUsername,
        creatorImageUrl: current.creatorImageUrl,
        selectedFile: current.selectedFile,
        likes: likes,
        createdAt: current.createdAt,
      );
    });
    widget.onToggleLike(post.id);
  }

  Future<void> _handleDelete(Post post) async {
    await widget.onDelete(post);
    // Nothing left in this viewer to show for a deleted post — close back
    // to the grid, which already reflects the deletion (see ProfilePage).
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              final isOwner =
                  widget.currentUserId != null && widget.currentUserId == post.creatorId;
              return _PostViewerItem(
                post: post,
                liked: widget.currentUserId != null && post.likedBy(widget.currentUserId!),
                isOwner: isOwner,
                onToggleLike: () => _handleToggleLike(post),
                onEdit: () => widget.onEdit(post),
                onDelete: () => _handleDelete(post),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostViewerItem extends StatelessWidget {
  const _PostViewerItem({
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
    final hasImage = post.selectedFile != null && post.selectedFile!.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(52, 8, 8, 8),
            child: Row(
              children: [
                _Avatar(imageUrl: post.creatorImageUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.creatorUsername.isNotEmpty ? post.creatorUsername : post.creatorName,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz, color: AppColors.textLight),
                  onPressed: () => showPostOptionsSheet(
                    context,
                    isOwner: isOwner,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Hero(
              tag: 'post-${post.id}',
              child: hasImage
                  ? Image.network(post.selectedFile!, fit: BoxFit.contain, width: double.infinity)
                  : Container(
                      color: AppColors.surfaceDark,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Text(
                        post.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, color: AppColors.textLight),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActionIcon(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? AppColors.pink : AppColors.textLight,
                      onTap: onToggleLike,
                    ),
                    const SizedBox(width: 16),
                    _ActionIcon(
                      icon: Icons.mode_comment_outlined,
                      color: AppColors.textLight,
                      onTap: () => showComingSoon(context, 'Comments'),
                    ),
                    const SizedBox(width: 16),
                    _ActionIcon(
                      icon: Icons.send_outlined,
                      color: AppColors.textLight,
                      onTap: () => showComingSoon(context, 'Sharing'),
                    ),
                    const Spacer(),
                    _ActionIcon(
                      icon: Icons.bookmark_border,
                      color: AppColors.textLight,
                      onTap: () => showComingSoon(context, 'Saving posts'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${post.likes.length} likes',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight),
                ),
                if (post.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13.5, height: 1.35),
                      children: [
                        TextSpan(
                          text: '${post.creatorUsername} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: post.message),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => showComingSoon(context, 'Comments'),
                  child: Text(
                    'View comments',
                    style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo(post.createdAt),
                  style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Container(
          color: AppColors.backgroundDark,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, size: 16, color: AppColors.textLight)
              : Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
