import '../../../auth/domain/entities/user.dart';
import '../entities/user_search_page.dart';

abstract class ProfileRepository {
  Future<User> getUserById(String userId);

  /// Toggles the current user's follow of [targetId]. Returns (me, target)
  /// with their follower/following lists updated.
  Future<(User me, User target)> toggleFollow({
    required String userId,
    required String targetId,
  });

  Future<UserSearchPage> searchUsers({required String query, int page = 1});

  Future<List<User>> getSuggestedUsers();

  Future<List<User>> getFollowers(String userId);

  Future<List<User>> getFollowing(String userId);
}
