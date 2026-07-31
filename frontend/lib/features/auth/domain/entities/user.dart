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
}
