import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signup({
    required String firstname,
    required String lastname,
    required String username,
    required String email,
    required String password,
  });

  Future<User> login({required String email, required String password});

  /// Restores a previously logged-in session (e.g. on app start), if one
  /// exists and the stored user id still resolves to a real account.
  Future<User?> restoreSession();

  Future<void> logout();
}
