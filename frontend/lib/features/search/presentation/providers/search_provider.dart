import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/usecases/get_suggested_users_usecase.dart';
import '../../../profile/domain/usecases/get_user_by_id_usecase.dart';
import '../../../profile/domain/usecases/search_users_usecase.dart';
import '../../../profile/domain/usecases/toggle_follow_usecase.dart';
import '../../../profile/presentation/providers/follow_list_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class SearchState {
  const SearchState({
    required this.query,
    required this.suggested,
    required this.results,
    required this.isSearching,
    required this.hasSearched,
    required this.currentPage,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final String query;
  final AsyncValue<List<User>> suggested;
  final List<User> results;
  final bool isSearching;
  final bool hasSearched;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  bool get isQueryEmpty => query.trim().isEmpty;

  SearchState copyWith({
    String? query,
    AsyncValue<List<User>>? suggested,
    List<User>? results,
    bool? isSearching,
    bool? hasSearched,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      suggested: suggested ?? this.suggested,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SearchViewModel extends Notifier<SearchState> {
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    _loadSuggested();
    return const SearchState(
      query: '',
      suggested: AsyncValue.loading(),
      results: [],
      isSearching: false,
      hasSearched: false,
      currentPage: 1,
      hasMore: false,
      isLoadingMore: false,
    );
  }

  Future<void> _loadSuggested() async {
    final suggested = await AsyncValue.guard(() => ref.read(getSuggestedUsersUsecaseProvider)());
    state = state.copyWith(suggested: suggested);
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], hasSearched: false, isSearching: false);
      return;
    }

    _debounce = Timer(_debounceDuration, () => _search(query));
  }

  Future<void> _search(String query) async {
    state = state.copyWith(isSearching: true);
    final currentUserId = ref.read(authViewModelProvider).valueOrNull?.id;

    try {
      final page = await ref.read(searchUsersUsecaseProvider)(query: query, page: 1);
      // The query moved on while this request was in flight — drop it.
      if (query != state.query) return;
      state = state.copyWith(
        results: page.users.where((u) => u.id != currentUserId).toList(),
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        isSearching: false,
        hasSearched: true,
      );
    } catch (_) {
      if (query != state.query) return;
      state = state.copyWith(isSearching: false, hasSearched: true, results: []);
    }
  }

  Future<void> loadMoreResults() async {
    if (!state.hasMore || state.isLoadingMore || state.isSearching) return;

    state = state.copyWith(isLoadingMore: true);
    final query = state.query;
    final currentUserId = ref.read(authViewModelProvider).valueOrNull?.id;

    try {
      final page = await ref.read(searchUsersUsecaseProvider)(
        query: query,
        page: state.currentPage + 1,
      );
      if (query != state.query) return;
      state = state.copyWith(
        results: [
          ...state.results,
          ...page.users.where((u) => u.id != currentUserId),
        ],
        currentPage: page.currentPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleFollow(String targetId) async {
    final currentUserId = ref.read(authViewModelProvider).valueOrNull?.id;
    if (currentUserId == null) return;

    final (_, target) = await ref.read(toggleFollowUsecaseProvider)(
      userId: currentUserId,
      targetId: targetId,
    );

    state = state.copyWith(
      suggested: state.suggested.whenData(
        (users) => [for (final u in users) if (u.id == targetId) target else u],
      ),
      results: [for (final u in state.results) if (u.id == targetId) target else u],
    );

    // My own following count changed, and so did the target's followers —
    // if any of these were already viewed this session, they're cached and
    // won't refetch on their own otherwise. Invalidating a provider that
    // was never read is a harmless no-op, so it's safe to do unconditionally.
    ref.invalidate(profileViewModelProvider(currentUserId));
    ref.invalidate(profileViewModelProvider(targetId));
    ref.invalidate(followListViewModelProvider((currentUserId, FollowListKind.following)));
    ref.invalidate(followListViewModelProvider((targetId, FollowListKind.followers)));
  }

  /// Re-fetches [userId] and patches it into whichever list currently holds
  /// it. Used after returning from a pushed profile page: any follow (or
  /// other) change made there happened on a separate provider instance that
  /// this view model has no way to hear about on its own.
  Future<void> refreshUser(String userId) async {
    try {
      final user = await ref.read(getUserByIdUsecaseProvider)(userId);
      state = state.copyWith(
        suggested: state.suggested.whenData(
          (users) => [for (final u in users) if (u.id == userId) user else u],
        ),
        results: [for (final u in state.results) if (u.id == userId) user else u],
      );
    } catch (_) {
      // Best-effort refresh; leave the stale copy rather than surface an
      // error for a page the user has already navigated away from.
    }
  }
}

final searchViewModelProvider = NotifierProvider<SearchViewModel, SearchState>(
  SearchViewModel.new,
);
