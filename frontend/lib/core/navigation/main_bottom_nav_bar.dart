import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app-wide bottom bar: Home / Search / Messages / Profile. Messages is
/// a one-off action (never "selected"); the other three map onto
/// [selectedIndex] in the parent shell's IndexedStack.
class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onMessagesTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMessagesTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavIcon(
                  icon: Icons.home_filled,
                  isActive: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _NavIcon(
                  icon: Icons.search,
                  isActive: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                _NavIcon(icon: Icons.send_outlined, onTap: onMessagesTap),
                _NavIcon(
                  icon: Icons.person_outline,
                  isActive: selectedIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.onTap, this.isActive = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: isActive
          ? Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            )
          : SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                color: AppColors.textLight.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
    );
  }
}
