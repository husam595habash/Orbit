import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<User> signup({
    required String firstname,
    required String lastname,
    required String username,
    required String email,
    required String password,
  }) async {
    final data = await _remoteDataSource.signup(
      firstname: firstname,
      lastname: lastname,
      username: username,
      email: email,
      password: password,
    );
    return _persistSessionAndParseUser(data);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final data = await _remoteDataSource.login(email: email, password: password);
    return _persistSessionAndParseUser(data);
  }

  @override
  Future<User?> restoreSession() async {
    final userId = await _tokenStorage.readUserId();
    final token = await _tokenStorage.readToken();
    if (userId == null || token == null) return null;

    try {
      return await _remoteDataSource.getUser(userId);
    } on DioException {
      await _tokenStorage.clearSession();
      return null;
    }
  }

  @override
  Future<void> logout() => _tokenStorage.clearSession();

  Future<User> _persistSessionAndParseUser(Map<String, dynamic> data) async {
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.saveSession(token: data['token'] as String, userId: user.id);
    return user;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  );
});
