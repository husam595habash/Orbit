import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/post.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import '../../domain/usecases/toggle_like_usecase.dart';
import '../../domain/usecases/update_post_usecase.dart';

class FeedState {
  const FeedState({
    required this.posts,
    required this.currentPage,
    required this.hasMore,
  });

  final List<Post> posts;
  final int currentPage;
  final bool hasMore;

  FeedState copyWith({List<Post>? posts, int? currentPage, bool? hasMore}) {
    return FeedState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedViewModel extends AsyncNotifier<FeedState> {
  bool _isFetchingMore = false;

  @override
  Future<FeedState> build() async {
    final page = await ref.read(getFeedUsecaseProvider)(page: 1);
    return FeedState(
      posts: page.posts,
      currentPage: page.currentPage,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final page = await ref.read(getFeedUsecaseProvider)(page: 1);
      return FeedState(
        posts: page.posts,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    try {
      final page = await ref.read(getFeedUsecaseProvider)(
        page: current.currentPage + 1,
      );
      final previous = state.valueOrNull ?? current;
      state = AsyncValue.data(
        previous.copyWith(
          posts: [...previous.posts, ...page.posts],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        ),
      );
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = await ref.read(toggleLikeUsecaseProvider)(postId);
    final posts = [
      for (final post in current.posts)
        if (post.id == postId)
          Post(
            id: updated.id,
            title: updated.title,
            message: updated.message,
            creatorId: updated.creatorId,
            // The like endpoint returns the bare post, so keep the creator
            // display fields already attached from the feed listing.
            creatorName: post.creatorName,
            creatorUsername: post.creatorUsername,
            creatorImageUrl: post.creatorImageUrl,
            selectedFile: updated.selectedFile,
            likes: updated.likes,
            createdAt: updated.createdAt,
          )
        else
          post,
    ];
    state = AsyncValue.data(current.copyWith(posts: posts));
  }

  Future<void> createPost({
    required String message,
    String? imageUrl,
    required String authorName,
    required String authorImageUrl,
  }) async {
    final created = await ref.read(createPostUsecaseProvider)(
      message: message,
      imageUrl: imageUrl,
    );
    // The create endpoint returns the bare post (no creator display fields
    // attached), so fill them in from the author who just posted it.
    final post = Post(
      id: created.id,
      title: created.title,
      message: created.message,
      creatorId: created.creatorId,
      creatorName: authorName,
      creatorUsername: authorName,
      creatorImageUrl: authorImageUrl,
      selectedFile: created.selectedFile,
      likes: created.likes,
      createdAt: created.createdAt,
    );

    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(posts: [post, ...current.posts]));
  }

  Future<void> updatePost(String postId, String message) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = await ref.read(updatePostUsecaseProvider)(postId, message: message);
    // The update endpoint returns the bare post, so keep the creator display
    // fields already attached from the feed listing.
    final posts = [
      for (final post in current.posts)
        if (post.id == postId)
          Post(
            id: updated.id,
            title: updated.title,
            message: updated.message,
            creatorId: updated.creatorId,
            creatorName: post.creatorName,
            creatorUsername: post.creatorUsername,
            creatorImageUrl: post.creatorImageUrl,
            selectedFile: updated.selectedFile,
            likes: updated.likes,
            createdAt: updated.createdAt,
          )
        else
          post,
    ];
    state = AsyncValue.data(current.copyWith(posts: posts));
  }

  Future<void> deletePost(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    await ref.read(deletePostUsecaseProvider)(postId);
    state = AsyncValue.data(
      current.copyWith(
        posts: current.posts.where((post) => post.id != postId).toList(),
      ),
    );
  }
}

final feedViewModelProvider = AsyncNotifierProvider<FeedViewModel, FeedState>(
  FeedViewModel.new,
);
