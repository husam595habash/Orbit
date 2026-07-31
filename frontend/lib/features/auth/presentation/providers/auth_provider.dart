import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

class AuthViewModel extends AsyncNotifier<User?> {
  @override
  Future<User?> build() {
    return ref.read(restoreSessionUsecaseProvider)();
  }

  Future<void> login({required String email, required String password}) async {
    // Preserve the previous value (hasValue stays true) so the UI can tell
    // "logging in" apart from "we don't know the session state yet" and
    // keep the login form mounted instead of swapping to a splash screen.
    state = const AsyncValue<User?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(loginUsecaseProvider)(email: email, password: password),
    );
  }

  Future<void> signup({
    required String firstname,
    required String lastname,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<User?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(signupUsecaseProvider)(
            firstname: firstname,
            lastname: lastname,
            username: username,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(logoutUsecaseProvider)();
    state = const AsyncValue.data(null);
  }
}

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, User?>(
  AuthViewModel.new,
);
