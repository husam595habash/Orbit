import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/feed/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../utils/coming_soon.dart';
import 'main_bottom_nav_bar.dart';

/// Owns the persistent bottom nav bar and the three main tabs (Home, Search,
/// Profile) as an [IndexedStack], so switching tabs never disposes their
/// state or scroll position — only pushing a sub-page (an edited post, the
/// camera flow, Notifications, ...) does that, and those pushes correctly
/// cover the bottom nav, matching Instagram.
///
/// Create Post and Notifications live on Home's own app bar, not here —
/// see [HomePage].
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  int _selectedIndex = 0;
  late final List<Widget> _tabs = [
    const HomePage(),
    const SearchPage(),
    ProfilePage(userId: ref.read(authViewModelProvider).valueOrNull!.id),
  ];

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: MainBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _selectTab,
        onMessagesTap: () => showComingSoon(context, 'Direct messages'),
      ),
    );
  }
}
