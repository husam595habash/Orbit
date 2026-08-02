import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/user_search_page.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/user_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource);

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<User> getUserById(String userId) => _remoteDataSource.getUserById(userId);

  @override
  Future<(User me, User target)> toggleFollow({
    required String userId,
    required String targetId,
  }) => _remoteDataSource.toggleFollow(userId: userId, targetId: targetId);

  @override
  Future<UserSearchPage> searchUsers({required String query, int page = 1}) async {
    final data = await _remoteDataSource.searchUsers(query: query, page: page);
    final users = (data['users'] as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return UserSearchPage(
      users: users,
      currentPage: data['currentPage'] as int,
      hasMore: data['hasMore'] as bool,
    );
  }

  @override
  Future<List<User>> getSuggestedUsers() => _remoteDataSource.getSuggestedUsers();

  @override
  Future<List<User>> getFollowers(String userId) => _remoteDataSource.getFollowers(userId);

  @override
  Future<List<User>> getFollowing(String userId) => _remoteDataSource.getFollowing(userId);
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});
