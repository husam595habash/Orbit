import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_repository_impl.dart';
import '../entities/feed_page.dart';
import '../repositories/post_repository.dart';

class GetFeedUsecase {
  GetFeedUsecase(this._repository);

  final PostRepository _repository;

  Future<FeedPage> call({int page = 1}) => _repository.getFeed(page: page);
}

final getFeedUsecaseProvider = Provider<GetFeedUsecase>((ref) {
  return GetFeedUsecase(ref.watch(postRepositoryProvider));
});
