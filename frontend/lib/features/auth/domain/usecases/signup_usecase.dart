import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignupUsecase {
  SignupUsecase(this._repository);

  final AuthRepository _repository;

  Future<User> call({
    required String firstname,
    required String lastname,
    required String username,
    required String email,
    required String password,
  }) {
    return _repository.signup(
      firstname: firstname,
      lastname: lastname,
      username: username,
      email: email,
      password: password,
    );
  }
}

final signupUsecaseProvider = Provider<SignupUsecase>((ref) {
  return SignupUsecase(ref.watch(authRepositoryProvider));
});
