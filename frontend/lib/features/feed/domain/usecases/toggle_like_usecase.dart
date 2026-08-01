import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class ToggleLikeUsecase {
  ToggleLikeUsecase(this._repository);

  final PostRepository _repository;

  Future<Post> call(String postId) => _repository.toggleLike(postId);
}

final toggleLikeUsecaseProvider = Provider<ToggleLikeUsecase>((ref) {
  return ToggleLikeUsecase(ref.watch(postRepositoryProvider));
});
