import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../profile/presentation/widgets/user_card.dart';
import '../../../profile/presentation/widgets/user_card_skeleton.dart';
import 'empty_search_state.dart';

/// Live search results — replaces [SuggestedUsersSection] as soon as the
/// query is non-empty.
class SearchResultsSection extends StatelessWidget {
  const SearchResultsSection({
    super.key,
    required this.query,
    required this.results,
    required this.isSearching,
    required this.hasSearched,
    required this.isLoadingMore,
    required this.currentUser,
    required this.scrollController,
    required this.onOpenProfile,
    required this.onToggleFollow,
  });

  final String query;
  final List<User> results;
  final bool isSearching;
  final bool hasSearched;
  final bool isLoadingMore;
  final User? currentUser;
  final ScrollController scrollController;
  final void Function(String userId) onOpenProfile;
  final void Function(String userId) onToggleFollow;

  @override
  Widget build(BuildContext context) {
    if (isSearching && results.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => const UserCardSkeleton(),
      );
    }

    if (hasSearched && results.isEmpty) {
      return SingleChildScrollView(child: EmptySearchState(query: query));
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).padding.bottom + 96),
      itemCount: results.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final user = results[index];
        final isFollowing = currentUser != null && user.followers.contains(currentUser!.id);
        final mutualCount = currentUser == null
            ? 0
            : currentUser!.following.toSet().intersection(user.followers.toSet()).length;
        return UserCard(
          user: user,
          isFollowing: isFollowing,
          mutualCount: mutualCount,
          onTap: () => onOpenProfile(user.id),
          onToggleFollow: () => onToggleFollow(user.id),
        );
      },
    );
  }
}
