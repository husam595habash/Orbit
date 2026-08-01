import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../repositories/post_repository.dart';

class DeletePostUsecase {
  DeletePostUsecase(this._repository);

  final PostRepository _repository;

  Future<void> call(String postId) => _repository.deletePost(postId);
}

final deletePostUsecaseProvider = Provider<DeletePostUsecase>((ref) {
  return DeletePostUsecase(ref.watch(postRepositoryProvider));
});
