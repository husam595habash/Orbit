import '../../../auth/domain/entities/user.dart';

class UserSearchPage {
  const UserSearchPage({
    required this.users,
    required this.currentPage,
    required this.hasMore,
  });

  final List<User> users;
  final int currentPage;
  final bool hasMore;
}
