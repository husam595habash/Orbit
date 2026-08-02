import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/usecases/get_followers_usecase.dart';
import '../../domain/usecases/get_following_usecase.dart';
import '../../domain/usecases/toggle_follow_usecase.dart';
import 'profile_provider.dart';

enum FollowListKind { followers, following }

typedef FollowListArgs = (String userId, FollowListKind kind);

class FollowListViewModel extends FamilyAsyncNotifier<List<User>, FollowListArgs> {
  @override
  Future<List<User>> build(FollowListArgs args) {
    final (userId, kind) = args;
    return switch (kind) {
      FollowListKind.followers => ref.read(getFollowersUsecaseProvider)(userId),
      FollowListKind.following => ref.read(getFollowingUsecaseProvider)(userId),
    };
  }

  Future<void> toggleFollow(String targetId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final currentUserId = ref.read(authViewModelProvider).valueOrNull?.id;
    if (currentUserId == null) return;

    final (_, target) = await ref.read(toggleFollowUsecaseProvider)(
      userId: currentUserId,
      targetId: targetId,
    );
    state = AsyncValue.data([for (final u in current) if (u.id == targetId) target else u]);

    // Same reasoning as SearchViewModel.toggleFollow — any of these may
    // already be cached from an earlier visit and won't refetch on their
    // own. Skip whichever one is this exact instance — it's already been
    // patched above, and invalidating it too would just flash a needless
    // loading state on the list the user is currently looking at.
    final myFollowing = (currentUserId, FollowListKind.following);
    final theirFollowers = (targetId, FollowListKind.followers);
    if (arg != myFollowing) ref.invalidate(followListViewModelProvider(myFollowing));
    if (arg != theirFollowers) ref.invalidate(followListViewModelProvider(theirFollowers));
    ref.invalidate(profileViewModelProvider(currentUserId));
    ref.invalidate(profileViewModelProvider(targetId));
  }
}

final followListViewModelProvider =
    AsyncNotifierProvider.family<FollowListViewModel, List<User>, FollowListArgs>(
  FollowListViewModel.new,
);
