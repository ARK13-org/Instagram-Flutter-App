import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/screens/profile_screen.dart';
import 'package:instagram_ui/screens/update_post.dart';
import 'package:instagram_ui/utils/format.dart';
import 'package:instagram_ui/widgets/avatar.dart';
import 'package:instagram_ui/widgets/brand.dart';
import 'package:instagram_ui/widgets/state_views.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.compact = false,
    this.onOpenComments,
    this.onDeleted,
  });

  final Posts post;

  /// Detail screen: comments are shown below, so hide the preview here.
  final bool compact;
  final VoidCallback? onOpenComments;
  final VoidCallback? onDeleted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;

  Posts get post => widget.post;
  bool get _isOwner => post.user.id == Session.instance.userId;

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.user.id)),
    );
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UpdatePostScreen(post: post)),
    );
    if (changed == true) Session.instance.bump();
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will also remove its comments. It can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await deletePost(post.id);
      Session.instance.bump();
      widget.onDeleted?.call();
      messenger.showSnackBar(const SnackBar(content: Text('Post deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: post.imageUrl));
    showSnack(context, 'Image link copied');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = post.comments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
          child: Row(
            children: [
              UserAvatar(
                username: post.user.username,
                size: 34,
                ring: true,
                onTap: _openProfile,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _openProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      if (post.timestamp != null)
                        Text(
                          timeAgo(post.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (v) {
                  if (v == 'edit') _edit();
                  if (v == 'delete') _delete();
                  if (v == 'copy') _copyLink();
                },
                itemBuilder: (_) => [
                  if (_isOwner)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit caption'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Copy image link'),
                      ],
                    ),
                  ),
                  if (_isOwner)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: cs.error,
                          ),
                          const SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: cs.error)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // ---- image
        AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            post.imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Skeleton(
                child: SizedBox.expand(child: SkeletonBox(radius: 0)),
              );
            },
            errorBuilder: (context, error, stack) => Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 42,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Image unavailable',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ---- actions
        if (!widget.compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onOpenComments,
                  icon: const Icon(Icons.mode_comment_outlined),
                  tooltip: 'Comments',
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                IconButton(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.send_outlined),
                  tooltip: 'Copy link',
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 8),

        // ---- caption
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 14.5, height: 1.35),
                  children: [
                    TextSpan(
                      text: '${post.user.username} ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
                maxLines: _expanded ? null : 2,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
          ),

        // ---- comments preview
        if (!widget.compact) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: widget.onOpenComments,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (count > 0) ...[
                    Text(
                      count == 1
                          ? 'View 1 comment'
                          : 'View all $count comments',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: '${post.comments.last.user.username} ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: post.comments.last.text),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Text(
                      'Add a comment…',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}
