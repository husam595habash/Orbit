import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../repositories/profile_repository.dart';

class GetFollowersUsecase {
  GetFollowersUsecase(this._repository);

  final ProfileRepository _repository;

  Future<List<User>> call(String userId) => _repository.getFollowers(userId);
}

final getFollowersUsecaseProvider = Provider<GetFollowersUsecase>((ref) {
  return GetFollowersUsecase(ref.watch(profileRepositoryProvider));
});
