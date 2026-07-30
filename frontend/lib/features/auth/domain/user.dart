class User {
  const User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.email,
    this.bio = '',
    this.imageUrl = '',
    this.followers = const [],
    this.following = const [],
  });

  final String id;
  final String firstname;
  final String lastname;
  final String username;
  final String email;
  final String bio;
  final String imageUrl;
  final List<String> followers;
  final List<String> following;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
