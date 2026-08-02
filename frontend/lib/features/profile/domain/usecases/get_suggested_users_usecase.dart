import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../repositories/profile_repository.dart';

class GetSuggestedUsersUsecase {
  GetSuggestedUsersUsecase(this._repository);

  final ProfileRepository _repository;

  Future<List<User>> call() => _repository.getSuggestedUsers();
}

final getSuggestedUsersUsecaseProvider = Provider<GetSuggestedUsersUsecase>((ref) {
  return GetSuggestedUsersUsecase(ref.watch(profileRepositoryProvider));
});
