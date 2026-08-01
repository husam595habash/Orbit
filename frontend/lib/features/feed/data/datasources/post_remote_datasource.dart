import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/post_model.dart';

class PostRemoteDataSource {
  PostRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetches a page of posts. Omitting [profileId] returns the caller's feed
  /// (their own posts plus who they follow); passing it returns just that
  /// user's posts, for the profile grid.
  Future<Map<String, dynamic>> getPosts({required int page, String? profileId}) async {
    try {
      final response = await _dio.get(
        '/post',
        queryParameters: {
          'page': '$page',
          if (profileId != null) 'profileId': profileId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PostModel> toggleLike(String postId) async {
    try {
      final response = await _dio.patch('/post/$postId/like');
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PostModel> updatePost(String postId, {required String message}) async {
    try {
      final response = await _dio.patch(
        '/post/$postId',
        data: {'message': message},
      );
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/post/$postId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PostModel> createPost({
    required String title,
    required String message,
    String? selectedFile,
  }) async {
    try {
      final response = await _dio.post(
        '/post',
        data: {
          'title': title,
          'message': message,
          if (selectedFile != null) 'selectedFile': selectedFile,
        },
      );
      return PostModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSource(ref.watch(apiClientProvider));
});
