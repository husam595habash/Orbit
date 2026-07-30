import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user.dart';

class AuthViewModel extends AsyncNotifier<User?> {
  @override
  Future<User?> build() {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    // Preserve the previous value (hasValue stays true) so the UI can tell
    // "logging in" apart from "we don't know the session state yet" and
    // keep the login form mounted instead of swapping to a splash screen.
    state = const AsyncValue<User?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
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
      () => ref.read(authRepositoryProvider).signup(
            firstname: firstname,
            lastname: lastname,
            username: username,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, User?>(
  AuthViewModel.new,
);
