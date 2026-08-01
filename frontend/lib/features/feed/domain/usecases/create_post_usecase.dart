import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class CreatePostUsecase {
  CreatePostUsecase(this._repository);

  final PostRepository _repository;

  Future<Post> call({required String message, String? imageUrl}) {
    return _repository.createPost(message: message, imageUrl: imageUrl);
  }
}

final createPostUsecaseProvider = Provider<CreatePostUsecase>((ref) {
  return CreatePostUsecase(ref.watch(postRepositoryProvider));
});
