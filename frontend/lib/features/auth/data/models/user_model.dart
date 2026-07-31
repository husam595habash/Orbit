import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.firstname,
    required super.lastname,
    required super.username,
    required super.email,
    super.bio,
    super.imageUrl,
    super.followers,
    super.following,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      followers: (json['followers'] as List?)?.cast<String>() ?? const [],
      following: (json['following'] as List?)?.cast<String>() ?? const [],
    );
  }
}
