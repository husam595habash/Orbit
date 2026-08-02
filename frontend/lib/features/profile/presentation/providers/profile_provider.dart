import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/domain/usecases/get_user_posts_usecase.dart';
import '../../../feed/domain/usecases/toggle_like_usecase.dart';
import '../../domain/usecases/get_user_by_id_usecase.dart';
import '../../domain/usecases/toggle_follow_usecase.dart';
import 'follow_list_provider.dart';

class ProfileState {
  const ProfileState({
    required this.user,
    required this.posts,
    required this.currentPage,
    required this.totalPosts,
    required this.hasMore,
    required this.isOwnProfile,
  });

  final User user;
  final List<Post> posts;
  final int currentPage;
  final int totalPosts;
  final bool hasMore;
  final bool isOwnProfile;

  ProfileState copyWith({
    User? user,
    List<Post>? posts,
    int? currentPage,
    int? totalPosts,
    bool? hasMore,
  }) {
    return ProfileState(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      totalPosts: totalPosts ?? this.totalPosts,
      hasMore: hasMore ?? this.hasMore,
      isOwnProfile: isOwnProfile,
    );
  }
}

class ProfileViewModel extends FamilyAsyncNotifier<ProfileState, String> {
  bool _isFetchingMore = false;

  @override
  Future<ProfileState> build(String userId) async {
    final currentUserId = ref.watch(authViewModelProvider).valueOrNull?.id;

    final userFuture = ref.read(getUserByIdUsecaseProvider)(userId);
    final postsFuture = ref.read(getUserPostsUsecaseProvider)(userId: userId, page: 1);
    final user = await userFuture;
    final feedPage = await postsFuture;

    return ProfileState(
      user: user,
      posts: feedPage.posts,
      currentPage: feedPage.currentPage,
      totalPosts: feedPage.total,
      hasMore: feedPage.hasMore,
      isOwnProfile: currentUserId == userId,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }

  Future<void> loadMorePosts() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isFetchingMore) return;

    _isFetchingMore = true;
    try {
      final feedPage = await ref.read(getUserPostsUsecaseProvider)(
        userId: arg,
        page: current.currentPage + 1,
      );
      final latest = state.valueOrNull ?? current;
      state = AsyncValue.data(
        latest.copyWith(
          posts: [...latest.posts, ...feedPage.posts],
          currentPage: feedPage.currentPage,
          totalPosts: feedPage.total,
          hasMore: feedPage.hasMore,
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
            // display fields already attached from the profile listing.
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

  Future<void> toggleFollow() async {
    final current = state.valueOrNull;
    if (current == null || current.isOwnProfile) return;

    final currentUserId = ref.read(authViewModelProvider).valueOrNull?.id;
    if (currentUserId == null) return;

    final (_, target) = await ref.read(toggleFollowUsecaseProvider)(
      userId: currentUserId,
      targetId: arg,
    );
    state = AsyncValue.data(current.copyWith(user: target));

    // My own following count just changed, and so did the target's
    // followers — any of these may already be cached from an earlier visit
    // and won't refetch on their own otherwise.
    ref.invalidate(profileViewModelProvider(currentUserId));
    ref.invalidate(followListViewModelProvider((currentUserId, FollowListKind.following)));
    ref.invalidate(followListViewModelProvider((arg, FollowListKind.followers)));
  }
}

final profileViewModelProvider =
    AsyncNotifierProvider.family<ProfileViewModel, ProfileState, String>(
  ProfileViewModel.new,
);
