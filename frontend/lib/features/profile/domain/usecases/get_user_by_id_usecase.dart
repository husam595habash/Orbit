import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../repositories/profile_repository.dart';

class GetUserByIdUsecase {
  GetUserByIdUsecase(this._repository);

  final ProfileRepository _repository;

  Future<User> call(String userId) => _repository.getUserById(userId);
}

final getUserByIdUsecaseProvider = Provider<GetUserByIdUsecase>((ref) {
  return GetUserByIdUsecase(ref.watch(profileRepositoryProvider));
});
