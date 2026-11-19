import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/models/user_model.dart';
import 'package:instagram_ui/screens/profile_screen.dart';
import 'package:instagram_ui/widgets/avatar.dart';
import 'package:instagram_ui/widgets/brand.dart';
import 'package:instagram_ui/widgets/comments_panel.dart';
import 'package:instagram_ui/widgets/post_card.dart';
import 'package:instagram_ui/widgets/state_views.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Posts> _posts = [];
  List<User> _people = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    Session.instance.dataRevision.addListener(_silentReload);
  }

  @override
  void dispose() {
    Session.instance.dataRevision.removeListener(_silentReload);
    super.dispose();
  }

  void _silentReload() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([fetchAllPosts(), fetchUsers()]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<Posts>;
        _people = results[1] as List<User>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Widget _peopleStrip() {
    final withPosts = _people.where((u) => u.postsCount > 0).toList();
    if (withPosts.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: withPosts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final u = withPosts[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: u.id),
                  ),
                ),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      UserAvatar(username: u.username, size: 56, ring: true),
                      const SizedBox(height: 4),
                      Text(
                        u.id == Session.instance.userId ? 'You' : u.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget content;
    if (_loading && _posts.isEmpty) {
      content = ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: const [PostSkeleton(), PostSkeleton()],
      );
    } else if (_error != null && _posts.isEmpty) {
      content = ErrorView(message: _error!, onRetry: _load);
    } else if (_posts.isEmpty) {
      content = ListView(
        children: const [
          SizedBox(height: 120),
          EmptyView(
            icon: Icons.photo_library_outlined,
            title: 'No posts yet',
            subtitle: 'Be the first one. Tap the + tab to share a photo.',
          ),
        ],
      );
    } else {
      content = RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _posts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) return _peopleStrip();
            final post = _posts[i - 1];
            return Column(
              children: [
                PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  onOpenComments: () => showCommentsSheet(
                    context,
                    post,
                    onChanged: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ],
            );
          },
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(children: const [Wordmark(size: 30)]),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
