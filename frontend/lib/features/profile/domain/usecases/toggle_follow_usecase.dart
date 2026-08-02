import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../repositories/profile_repository.dart';

class ToggleFollowUsecase {
  ToggleFollowUsecase(this._repository);

  final ProfileRepository _repository;

  Future<(User me, User target)> call({
    required String userId,
    required String targetId,
  }) {
    return _repository.toggleFollow(userId: userId, targetId: targetId);
  }
}

final toggleFollowUsecaseProvider = Provider<ToggleFollowUsecase>((ref) {
  return ToggleFollowUsecase(ref.watch(profileRepositoryProvider));
});
