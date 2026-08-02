import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../providers/search_provider.dart';
import '../widgets/search_bar_field.dart';
import '../widgets/search_results_section.dart';
import '../widgets/suggested_users_section.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  static const _loadMoreThreshold = 300.0;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(searchViewModelProvider.notifier).loadMoreResults();
    }
  }

  void _onQueryChanged(String value) {
    ref.read(searchViewModelProvider.notifier).onQueryChanged(value);
    // The clear button's visibility depends on controller.text, not on
    // riverpod state, so it needs its own rebuild trigger.
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    _onQueryChanged('');
  }

  Future<void> _openProfile(String userId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
    );
    // Anything that changed on that profile (e.g. its follow state) lives
    // on a separate provider instance — refresh our own copy on return.
    if (mounted) ref.read(searchViewModelProvider.notifier).refreshUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final currentUser = ref.watch(authViewModelProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SearchBarField(
                controller: _controller,
                onChanged: _onQueryChanged,
                onClear: _clear,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: state.isQueryEmpty
                    ? SuggestedUsersSection(
                        key: const ValueKey('suggested'),
                        suggested: state.suggested,
                        currentUser: currentUser,
                        onOpenProfile: _openProfile,
                        onToggleFollow: (id) =>
                            ref.read(searchViewModelProvider.notifier).toggleFollow(id),
                      )
                    : SearchResultsSection(
                        key: const ValueKey('results'),
                        query: state.query,
                        results: state.results,
                        isSearching: state.isSearching,
                        hasSearched: state.hasSearched,
                        isLoadingMore: state.isLoadingMore,
                        currentUser: currentUser,
                        scrollController: _scrollController,
                        onOpenProfile: _openProfile,
                        onToggleFollow: (id) =>
                            ref.read(searchViewModelProvider.notifier).toggleFollow(id),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
