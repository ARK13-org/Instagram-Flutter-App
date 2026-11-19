import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/screens/profile_screen.dart';
import 'package:instagram_ui/theme/app_theme.dart';
import 'package:instagram_ui/utils/format.dart';
import 'package:instagram_ui/widgets/avatar.dart';
import 'package:instagram_ui/widgets/brand.dart';
import 'package:instagram_ui/widgets/state_views.dart';

/// Opens the comments of [post] in a draggable bottom sheet.
Future<void> showCommentsSheet(
  BuildContext context,
  Posts post, {
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, controller) => CommentsPanel(
            post: post,
            onChanged: onChanged,
            scrollController: controller,
            showTitle: true,
          ),
        ),
      );
    },
  );
}

/// Comment list + composer. Used in the bottom sheet and on the post screen.
class CommentsPanel extends StatefulWidget {
  const CommentsPanel({
    super.key,
    required this.post,
    required this.onChanged,
    this.header,
    this.scrollController,
    this.showTitle = false,
  });

  final Posts post;
  final VoidCallback onChanged;
  final Widget? header;
  final ScrollController? scrollController;
  final bool showTitle;

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _ownController = ScrollController();

  late List<Comment> _comments = List<Comment>.of(widget.post.comments);
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Comment? _editing;

  ScrollController get _sc => widget.scrollController ?? _ownController;
  int? get _me => Session.instance.userId;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _ownController.dispose();
    super.dispose();
  }

  void _sync() {
    widget.post.comments = List<Comment>.of(_comments);
    widget.onChanged();
  }

  Future<void> _load() async {
    try {
      final list = await fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
        _error = null;
      });
      _sync();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sc.hasClients) return;
      _sc.animateTo(
        _sc.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _submit() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final editing = _editing;
    setState(() => _sending = true);
    try {
      if (editing != null) {
        final updated = await updateComment(editing.id, text);
        final i = _comments.indexWhere((c) => c.id == editing.id);
        if (i >= 0) _comments[i] = updated;
      } else {
        final created = await createComment(widget.post.id, text);
        _comments.add(created);
        _scrollToEnd();
      }
      _sync();
      if (!mounted) return;
      _input.clear();
      _editing = null;
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Comment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
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
      await deleteComment(c.id);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((x) => x.id == c.id);
        if (_editing?.id == c.id) {
          _editing = null;
          _input.clear();
        }
      });
      _sync();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  void _startEdit(Comment c) {
    setState(() => _editing = c);
    _input.text = c.text;
    _input.selection = TextSelection.collapsed(offset: c.text.length);
    _focus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _input.clear();
  }

  void _openProfile(int userId) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
  }

  Widget _tile(Comment c) {
    final cs = Theme.of(context).colorScheme;
    final mine = c.user.id == _me;
    final canDelete = mine || widget.post.user.id == _me;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            username: c.user.username,
            size: 36,
            onTap: () => _openProfile(c.user.id),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(c.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  c.text,
                  style: const TextStyle(fontSize: 14.5, height: 1.3),
                ),
              ],
            ),
          ),
          if (mine || canDelete)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) {
                if (v == 'edit') _startEdit(c);
                if (v == 'delete') _delete(c);
              },
              itemBuilder: (_) => [
                if (mine)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (canDelete)
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
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _composer() {
    final cs = Theme.of(context).colorScheme;
    final hasText = _input.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editing != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing comment',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _cancelEdit,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: UserAvatar(
                      username: Session.instance.username ?? '',
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          fieldDecoration(
                            context,
                            hint:
                                'Add a comment as ${Session.instance.username ?? 'you'}…',
                            counter: '',
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _sending
                        ? const SizedBox(
                            width: 44,
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: hasText ? _submit : null,
                            icon: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (r) =>
                                  (hasText
                                          ? Brand.gradient
                                          : LinearGradient(
                                              colors: [cs.outline, cs.outline],
                                            ))
                                      .createShader(
                                        Rect.fromLTWH(0, 0, r.width, r.height),
                                      ),
                              child: Icon(
                                _editing != null
                                    ? Icons.check_circle_rounded
                                    : Icons.send_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (widget.header != null) widget.header!,
      if (widget.showTitle)
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Center(
            child: Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      if (widget.header != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            _comments.isEmpty ? 'Comments' : 'Comments (${_comments.length})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      if (_loading && _comments.isEmpty)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_error != null && _comments.isEmpty)
        SizedBox(
          height: 220,
          child: ErrorView(
            message: _error!,
            onRetry: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
          ),
        )
      else if (_comments.isEmpty)
        const SizedBox(
          height: 220,
          child: EmptyView(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No comments yet',
            subtitle: 'Start the conversation.',
          ),
        )
      else
        ..._comments.map(_tile),
      const SizedBox(height: 12),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _sc,
            padding: EdgeInsets.zero,
            children: items,
          ),
        ),
        _composer(),
      ],
    );
  }
}
