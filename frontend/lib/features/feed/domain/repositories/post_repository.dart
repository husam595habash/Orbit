import '../entities/feed_page.dart';
import '../entities/post.dart';

abstract class PostRepository {
  /// Posts from users the current user follows (plus their own), paginated.
  Future<FeedPage> getFeed({int page = 1});

  /// A single user's posts, paginated — for their profile grid.
  Future<FeedPage> getUserPosts({required String userId, int page = 1});

  /// Toggles the current user's like on [postId] and returns the updated post.
  Future<Post> toggleLike(String postId);

  /// Updates [postId]'s caption. The backend rejects this unless the caller owns the post.
  Future<Post> updatePost(String postId, {required String message});

  /// Deletes [postId]. The backend rejects this unless the caller owns the post.
  Future<void> deletePost(String postId);

  /// Creates a new post. [imageUrl] must already be hosted (e.g. a Cloudinary
  /// upload result) — this repository does not upload image bytes itself.
  Future<Post> createPost({required String message, String? imageUrl});
}
