class User {
  final int id;
  final String username;
  final String? bio;
  final String? email; // only present on your own profile
  final DateTime? createdAt;
  final int postsCount;
  final int commentsCount;

  const User({
    required this.id,
    required this.username,
    this.bio,
    this.email,
    this.createdAt,
    this.postsCount = 0,
    this.commentsCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '').toString(),
      bio: json['bio'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    );
  }
}
