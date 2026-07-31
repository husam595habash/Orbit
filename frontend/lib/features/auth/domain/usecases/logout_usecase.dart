import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase {
  LogoutUsecase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(ref.watch(authRepositoryProvider));
});
