import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/data/models/user_model.dart';

class UserRemoteDataSource {
  UserRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _dio.get('/user/$userId');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Toggles [userId]'s follow of [targetId]. Returns both updated users —
  /// the caller (updated `following`) and the target (updated `followers`).
  Future<(UserModel me, UserModel target)> toggleFollow({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.patch('/user/$userId/following/$targetId');
      final data = response.data as Map<String, dynamic>;
      return (
        UserModel.fromJson(data['user1'] as Map<String, dynamic>),
        UserModel.fromJson(data['user2'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> searchUsers({required String query, required int page}) async {
    try {
      final response = await _dio.get(
        '/user/search',
        queryParameters: {'q': query, 'page': '$page'},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// "Friends of friends" suggestions — not paginated backend-side (see
  /// UserService.get_suggested_users), so this always returns the full list.
  Future<List<UserModel>> getSuggestedUsers() async {
    try {
      final response = await _dio.get('/user/suggested');
      final data = response.data as Map<String, dynamic>;
      return (data['users'] as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _dio.get('/user/$userId/followers');
      final data = response.data as Map<String, dynamic>;
      return (data['users'] as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _dio.get('/user/$userId/following');
      final data = response.data as Map<String, dynamic>;
      return (data['users'] as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(apiClientProvider));
});
