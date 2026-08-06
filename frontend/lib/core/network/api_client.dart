import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../storage/token_storage.dart';
import 'backend_host.dart';

String get _backendBaseUrl => 'http://$backendHost:8000';

final apiClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(BaseOptions(baseUrl: _backendBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // A 401 from login/signup just means "wrong credentials" — entirely
        // expected, not a session problem, and there's no session to expire
        // yet. Only treat a 401 from an already-authenticated request as an
        // expired/invalid token: clear the session so AuthGate sends the
        // user to the login screen instead of leaving them stuck seeing
        // error messages on whatever screen they're on.
        final path = error.requestOptions.path;
        final isAuthEndpoint = path.contains('/login') || path.contains('/signup');
        if (error.response?.statusCode == 401 && !isAuthEndpoint) {
          ref.read(authViewModelProvider.notifier).logout();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
