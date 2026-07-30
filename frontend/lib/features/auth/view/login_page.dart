import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'signup_page.dart';
import 'widgets/logo_header.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _heroHeightFraction = 0.52;
  static const _heroTopGap = 32.0;
  static const _cardTopRadius = 36.0;
  static const _horizontalPadding = 24.0;
  static const _cardOverlap = 24.0;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _cardSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authViewModelProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;
    final errorMessage = (authState.hasError && !isLoading)
        ? authState.error.toString()
        : null;
    final heroHeight = MediaQuery.of(context).size.height * _heroHeightFraction;
    // The visible gap must clear the status bar/notch inset, or it's
    // invisible — swallowed entirely by that system overlay.
    final heroTopGap = MediaQuery.of(context).padding.top + _heroTopGap;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: heroTopGap),
              SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/login background.png',
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          // The fade lives entirely in the bottom ~50%, and
                          // reaches full opacity well before the very edge
                          // (a flat solid buffer) so the card — which
                          // overlaps upward into this zone — always meets
                          // pure backgroundDark with no visible seam.
                          stops: [0.5, 0.9, 1.0],
                          colors: [
                            Colors.transparent,
                            AppColors.backgroundDark,
                            AppColors.backgroundDark,
                          ],
                        ),
                      ),
                    ),
                    const SafeArea(
                      bottom: false,
                      child: Center(child: LogoHeader()),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -_cardOverlap),
                child: SlideTransition(
                  position: _cardSlideAnimation,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_cardTopRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _horizontalPadding,
                        36,
                        _horizontalPadding,
                        _horizontalPadding,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.mail_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Email is required'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Password is required'
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.purple,
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () => _showComingSoon('Password reset'),
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ErrorBanner(message: errorMessage),
                            GradientButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Log in'),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: AppColors.textLight.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const SignupPage(),
                                          ),
                                        ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => AppColors
                                        .brandGradient
                                        .createShader(bounds),
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
