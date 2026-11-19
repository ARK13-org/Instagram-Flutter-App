import 'package:instagram_ui/api/config.dart';
import 'package:instagram_ui/models/user_model.dart';

class Comment {
  final int id;
  final String text;
  final DateTime? timestamp;
  final User user;
  final int postId;

  const Comment({
    required this.id,
    required this.text,
    required this.user,
    required this.postId,
    this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: (json['text'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
      user: User.fromJson((json['user'] as Map<String, dynamic>?) ?? const {}),
      postId: (json['post_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class Posts {
  final int id;
  String caption;
  final String imageUrl;
  final DateTime? timestamp;
  final User user;
  List<Comment> comments;

  Posts({
    required this.id,
    required this.caption,
    required this.imageUrl,
    required this.user,
    this.timestamp,
    List<Comment>? comments,
  }) : comments = comments ?? <Comment>[];

  factory Posts.fromJson(Map<String, dynamic> json) {
    final rawComments = (json['comments'] as List?) ?? const [];
    return Posts(
      id: (json['id'] as num?)?.toInt() ?? 0,
      caption: (json['caption'] ?? '').toString(),
      imageUrl: resolveImageUrl(json['image_url'] as String?),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
      user: User.fromJson((json['user'] as Map<String, dynamic>?) ?? const {}),
      comments: rawComments
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
