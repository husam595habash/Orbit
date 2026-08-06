import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/presentation/pages/edit_post_page.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../providers/follow_list_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/empty_posts_view.dart';
import '../widgets/posts_grid.dart';
import '../widgets/profile_header.dart';
import 'follow_list_page.dart';
import 'post_viewer_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const _loadMoreThreshold = 300.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(profileViewModelProvider(widget.userId).notifier).loadMorePosts();
    }
  }

  Future<void> _editPost(Post post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditPostPage(post: post)),
    );
    // The editor updates the feed's copy directly; refetch ours so the grid
    // and viewer catch up.
    ref.invalidate(profileViewModelProvider(widget.userId));
  }

  Future<void> _deletePost(Post post) async {
    await ref.read(feedViewModelProvider.notifier).deletePost(post.id);
    ref.invalidate(profileViewModelProvider(widget.userId));
  }

  void _openFollowList(FollowListKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FollowListPage(userId: widget.userId, kind: kind)),
    );
  }

  void _openConversation(User user) {
    final fullName = '${user.firstname} ${user.lastname}'.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(
          partnerId: user.id,
          partnerName: fullName.isNotEmpty ? fullName : user.username,
          partnerImageUrl: user.imageUrl,
        ),
      ),
    );
  }

  void _openViewer(List<Post> posts, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostViewerPage(
          posts: posts,
          initialIndex: index,
          currentUserId: ref.read(authViewModelProvider).valueOrNull?.id,
          onToggleLike: (postId) =>
              ref.read(profileViewModelProvider(widget.userId).notifier).toggleLike(postId),
          onEdit: _editPost,
          onDelete: _deletePost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(profileState.valueOrNull?.user.username ?? ''),
        actions: [
          if (profileState.valueOrNull?.isOwnProfile ?? false)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _showSettingsSheet(context),
            ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(profileViewModelProvider(widget.userId).notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final currentUserId = ref.read(authViewModelProvider).valueOrNull?.id;
          final isFollowing =
              currentUserId != null && state.user.followers.contains(currentUserId);

          return RefreshIndicator(
            onRefresh: () => ref.read(profileViewModelProvider(widget.userId).notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    user: state.user,
                    postsCount: state.totalPosts,
                    isOwnProfile: state.isOwnProfile,
                    isFollowing: isFollowing,
                    onToggleFollow: () =>
                        ref.read(profileViewModelProvider(widget.userId).notifier).toggleFollow(),
                    onTapFollowers: () => _openFollowList(FollowListKind.followers),
                    onTapFollowing: () => _openFollowList(FollowListKind.following),
                    onMessage: () => _openConversation(state.user),
                  ),
                ),
                if (state.posts.isEmpty)
                  const SliverToBoxAdapter(child: EmptyPostsView())
                else
                  PostsGrid(
                    posts: state.posts,
                    onTapPost: (index) => _openViewer(state.posts, index),
                  ),
                // Profile now lives behind the floating bottom nav bar (see
                // MainShellPage's extendBody), so clear it like the feed does.
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(authViewModelProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
