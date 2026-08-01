import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/feed_page.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._remoteDataSource);

  final PostRemoteDataSource _remoteDataSource;

  @override
  Future<FeedPage> getFeed({int page = 1}) => _fetchPage(page: page);

  @override
  Future<FeedPage> getUserPosts({required String userId, int page = 1}) =>
      _fetchPage(page: page, profileId: userId);

  Future<FeedPage> _fetchPage({required int page, String? profileId}) async {
    final data = await _remoteDataSource.getPosts(page: page, profileId: profileId);
    final posts = (data['posts'] as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
    return FeedPage(
      posts: posts,
      currentPage: data['currentPage'] as int,
      numberOfPages: data['numberOfPages'] as int,
      total: data['total'] as int? ?? posts.length,
    );
  }

  @override
  Future<Post> toggleLike(String postId) => _remoteDataSource.toggleLike(postId);

  @override
  Future<Post> updatePost(String postId, {required String message}) =>
      _remoteDataSource.updatePost(postId, message: message);

  @override
  Future<void> deletePost(String postId) => _remoteDataSource.deletePost(postId);

  @override
  Future<Post> createPost({required String message, String? imageUrl}) {
    // The backend requires a title, but this app's UI is caption-only —
    // reuse the caption so callers don't need to think about the field.
    final title = message.trim().isEmpty ? 'Untitled' : message;
    return _remoteDataSource.createPost(
      title: title,
      message: message,
      selectedFile: imageUrl,
    );
  }
}

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(ref.watch(postRemoteDataSourceProvider));
});
