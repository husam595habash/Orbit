import '../../domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.message,
    required super.creatorId,
    required super.creatorName,
    required super.creatorUsername,
    required super.creatorImageUrl,
    required super.selectedFile,
    required super.likes,
    required super.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      creatorId: json['creator'] as String,
      creatorName: json['name'] as String? ?? '',
      creatorUsername: json['username'] as String? ?? '',
      creatorImageUrl: json['creatorImageUrl'] as String? ?? '',
      selectedFile: json['selectedFile'] as String?,
      likes: (json['likes'] as List?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
