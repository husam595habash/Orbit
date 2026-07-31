import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit',
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Routes to the login flow or the signed-in area depending on session state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    // Only the very first load (restoring a session on app start) is unknown
    // in a way that warrants a full-screen splash. Once we have any value
    // (including `null`, i.e. logged out), keep the login/signed-in page
    // mounted through subsequent login/signup attempts instead of tearing it
    // down — otherwise its error SnackBar listener never gets a chance to fire.
    if (authState.isLoading && !authState.hasValue) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.valueOrNull;
    return user == null ? const LoginPage() : _SignedInPlaceholder(username: user.username);
  }
}

class _SignedInPlaceholder extends ConsumerWidget {
  const _SignedInPlaceholder({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $username')),
      body: Center(
        child: FilledButton(
          onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
          child: const Text('Log out'),
        ),
      ),
    );
  }
}
