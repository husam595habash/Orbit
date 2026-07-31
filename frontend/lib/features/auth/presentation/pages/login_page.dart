import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/login_form.dart';
import '../widgets/logo_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const _heroHeightFraction = 0.52;
  static const _cardTopRadius = 36.0;
  static const _horizontalPadding = 24.0;
  static const _cardOverlap = 24.0;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _cardSlideAnimation;

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
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.height * _heroHeightFraction;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero image bleeds all the way to the top of the screen,
                    // behind the status bar and Dynamic Island.
                    Image.asset(
                      'assets/images/login background.png',
                      fit: BoxFit.cover,
                    ),
                    // Bottom fade so the image dissolves into the dark card.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.5, 0.9, 1.0],
                          colors: [
                            Colors.transparent,
                            AppColors.backgroundDark,
                            AppColors.backgroundDark,
                          ],
                        ),
                      ),
                    ),
                    // Subtle top gradient so the status bar text/icons remain
                    // readable (≈25 % black → transparent over the top 20 %).
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.20],
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Logo and title respect the safe area (notch / Dynamic
                    // Island) while the image behind them does not.
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
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(
                        _horizontalPadding,
                        36,
                        _horizontalPadding,
                        _horizontalPadding,
                      ),
                      child: LoginForm(),
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
