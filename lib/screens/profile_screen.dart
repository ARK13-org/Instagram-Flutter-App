import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/models/user_model.dart';
import 'package:instagram_ui/screens/post_detail_screen.dart';
import 'package:instagram_ui/utils/format.dart';
import 'package:instagram_ui/widgets/avatar.dart';
import 'package:instagram_ui/widgets/brand.dart';
import 'package:instagram_ui/widgets/state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId, this.embedded = false});

  final int userId;

  /// True when shown as a bottom-navigation tab (no back button).
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Posts> _posts = [];
  bool _loading = true;
  String? _error;

  bool get _isMe => widget.userId == Session.instance.userId;

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
      final results = await Future.wait([
        _isMe ? fetchMe() : fetchUser(widget.userId),
        fetchPostsByUser(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _posts = results[1] as List<Posts>;
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

  Future<void> _editProfile() async {
    final user = _user;
    if (user == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
    if (saved == true) Session.instance.bump();
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await Session.instance.signOut();
  }

  Widget _stat(String value, String label) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }

  Widget _header(User user) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(username: user.username, size: 82, ring: true),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${_posts.length}', 'Posts'),
                    _stat('${user.commentsCount}', 'Comments'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.username,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if ((user.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.bio!,
              style: const TextStyle(fontSize: 14.5, height: 1.35),
            ),
          ],
          if (user.createdAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  'Joined ${monthYear(user.createdAt)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ],
          if (_isMe) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _editProfile,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit profile',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _signOut,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.logout_rounded, size: 20),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Icon(Icons.grid_on_rounded, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = _user;

    Widget body;
    if (_loading && user == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && user == null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (user == null) {
      body = const SizedBox.shrink();
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(user)),
            if (_posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  icon: Icons.photo_camera_outlined,
                  title: _isMe ? 'Share your first photo' : 'No posts yet',
                  subtitle: _isMe
                      ? 'Tap the + tab to post a picture.'
                      : '${user.username} hasn’t posted anything.',
                ),
              )
            else
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final p = _posts[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: p),
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          p.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                        if (p.comments.isNotEmpty)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.mode_comment,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${p.comments.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }, childCount: _posts.length),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        centerTitle: false,
        title: Text(
          user?.username ?? 'Profile',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: body,
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});
  final User user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _bio = TextEditingController(
    text: widget.user.bio ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _bio.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      await updateMe(
        bio: _bio.text.trim(),
        email: email.isEmpty || email == widget.user.email ? null : email,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _bio,
              minLines: 2,
              maxLines: 4,
              maxLength: 150,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration(context, label: 'Bio'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: fieldDecoration(
                context,
                label: 'Email',
                icon: Icons.mail_outline_rounded,
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(label: 'Save', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
