import 'post.dart';

class FeedPage {
  const FeedPage({
    required this.posts,
    required this.currentPage,
    required this.numberOfPages,
    required this.total,
  });

  final List<Post> posts;
  final int currentPage;
  final int numberOfPages;
  final int total;

  bool get hasMore => currentPage < numberOfPages;
}
