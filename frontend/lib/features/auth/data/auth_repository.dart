import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<User> signup({
    required String firstname,
    required String lastname,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/user/signup', data: {
        'firstname': firstname,
        'lastname': lastname,
        'username': username,
        'email': email,
        'password': password,
      });
      return _persistSessionAndParseUser(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/user/login', data: {
        'email': email,
        'password': password,
      });
      return _persistSessionAndParseUser(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Restores a previously logged-in session (e.g. on app start), if one
  /// exists and the stored user id still resolves to a real account.
  Future<User?> restoreSession() async {
    final userId = await _tokenStorage.readUserId();
    final token = await _tokenStorage.readToken();
    if (userId == null || token == null) return null;

    try {
      final response = await _dio.get('/user/$userId');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      await _tokenStorage.clearSession();
      return null;
    }
  }

  Future<void> logout() => _tokenStorage.clearSession();

  Future<User> _persistSessionAndParseUser(Map<String, dynamic> data) async {
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.saveSession(token: data['token'] as String, userId: user.id);
    return user;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
