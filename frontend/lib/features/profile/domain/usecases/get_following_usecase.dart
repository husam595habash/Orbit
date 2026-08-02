import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../repositories/profile_repository.dart';

class GetFollowingUsecase {
  GetFollowingUsecase(this._repository);

  final ProfileRepository _repository;

  Future<List<User>> call(String userId) => _repository.getFollowing(userId);
}

final getFollowingUsecaseProvider = Provider<GetFollowingUsecase>((ref) {
  return GetFollowingUsecase(ref.watch(profileRepositoryProvider));
});
