import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import 'camera_post_page.dart';
import 'edit_post_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
      ref.read(feedViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedViewModelProvider);
    final currentUser = ref.watch(authViewModelProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add_box_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CameraPostPage()),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
          child: const Text(
            'Orbit',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
        ],
      ),
      body: feedState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _FeedError(
          message: error.toString(),
          onRetry: () => ref.read(feedViewModelProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(feedViewModelProvider.notifier).refresh(),
              child: ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 120, bottom: 100),
                    child: Center(
                      child: Text(
                        'No posts yet.\nFollow people to see their posts here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(feedViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 96,
              ),
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                final post = state.posts[index];
                return PostCard(
                  post: post,
                  currentUserId: currentUser?.id,
                  onToggleLike: () =>
                      ref.read(feedViewModelProvider.notifier).toggleLike(post.id),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditPostPage(post: post)),
                  ),
                  onDelete: () =>
                      ref.read(feedViewModelProvider.notifier).deletePost(post.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
