import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../entities/feed_page.dart';
import '../repositories/post_repository.dart';

class GetUserPostsUsecase {
  GetUserPostsUsecase(this._repository);

  final PostRepository _repository;

  Future<FeedPage> call({required String userId, int page = 1}) {
    return _repository.getUserPosts(userId: userId, page: page);
  }
}

final getUserPostsUsecaseProvider = Provider<GetUserPostsUsecase>((ref) {
  return GetUserPostsUsecase(ref.watch(postRepositoryProvider));
});
