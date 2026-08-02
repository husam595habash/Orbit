import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile_repository_impl.dart';
import '../entities/user_search_page.dart';
import '../repositories/profile_repository.dart';

class SearchUsersUsecase {
  SearchUsersUsecase(this._repository);

  final ProfileRepository _repository;

  Future<UserSearchPage> call({required String query, int page = 1}) {
    return _repository.searchUsers(query: query, page: page);
  }
}

final searchUsersUsecaseProvider = Provider<SearchUsersUsecase>((ref) {
  return SearchUsersUsecase(ref.watch(profileRepositoryProvider));
});
