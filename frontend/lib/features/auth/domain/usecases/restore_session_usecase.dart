import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUsecase {
  RestoreSessionUsecase(this._repository);

  final AuthRepository _repository;

  Future<User?> call() => _repository.restoreSession();
}

final restoreSessionUsecaseProvider = Provider<RestoreSessionUsecase>((ref) {
  return RestoreSessionUsecase(ref.watch(authRepositoryProvider));
});
