import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/widgets/comments_panel.dart';
import 'package:instagram_ui/widgets/post_card.dart';

/// One post with all of its comments and the comment box.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final Posts post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Posts _post = widget.post;

  @override
  void initState() {
    super.initState();
    Session.instance.dataRevision.addListener(_refresh);
  }

  @override
  void dispose() {
    Session.instance.dataRevision.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await fetchPost(_post.id);
      if (!mounted) return;
      setState(() => _post = fresh);
    } catch (_) {
      // deleted elsewhere or offline: keep what we have
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: CommentsPanel(
        key: ValueKey(_post.id),
        post: _post,
        onChanged: () {
          if (mounted) setState(() {});
        },
        header: PostCard(
          post: _post,
          compact: true,
          onDeleted: () {
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
