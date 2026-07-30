import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/gradient_button.dart';
import 'package:frontend/features/auth/domain/user.dart';
import 'package:frontend/features/auth/view/signup_page.dart';
import 'package:frontend/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:frontend/main.dart';

/// Skips the real session-restore call (network + secure storage aren't
/// available in a widget test) and reports "logged out" immediately.
class _LoggedOutAuthViewModel extends AuthViewModel {
  @override
  Future<User?> build() async => null;
}

void main() {
  testWidgets('shows the login page when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authViewModelProvider.overrideWith(_LoggedOutAuthViewModel.new)],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(GradientButton, 'Log in'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('signup page shows all fields including confirm password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authViewModelProvider.overrideWith(_LoggedOutAuthViewModel.new)],
        child: MaterialApp(theme: AppTheme.dark, home: const SignupPage()),
      ),
    );
    await tester.pump();

    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.widgetWithText(GradientButton, 'Sign up'), findsOneWidget);

    // Mismatched passwords should be rejected.
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different',
    );
    final signupButton = find.widgetWithText(GradientButton, 'Sign up');
    await tester.ensureVisible(signupButton);
    await tester.tap(signupButton);
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
