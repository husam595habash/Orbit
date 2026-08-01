import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class UpdatePostUsecase {
  UpdatePostUsecase(this._repository);

  final PostRepository _repository;

  Future<Post> call(String postId, {required String message}) {
    return _repository.updatePost(postId, message: message);
  }
}

final updatePostUsecaseProvider = Provider<UpdatePostUsecase>((ref) {
  return UpdatePostUsecase(ref.watch(postRepositoryProvider));
});
