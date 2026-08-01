class Post {
  const Post({
    required this.id,
    required this.title,
    required this.message,
    required this.creatorId,
    required this.creatorName,
    required this.creatorUsername,
    required this.creatorImageUrl,
    required this.selectedFile,
    required this.likes,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String creatorId;
  final String creatorName;
  final String creatorUsername;
  final String creatorImageUrl;
  final String? selectedFile;
  final List<String> likes;
  final DateTime createdAt;

  bool likedBy(String userId) => likes.contains(userId);
}
