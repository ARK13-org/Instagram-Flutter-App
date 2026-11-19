import 'dart:async';

import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/user_model.dart';
import 'package:instagram_ui/screens/profile_screen.dart';
import 'package:instagram_ui/widgets/avatar.dart';
import 'package:instagram_ui/widgets/brand.dart';
import 'package:instagram_ui/widgets/state_views.dart';

/// Find people: searchable list of every user.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  List<User> _users = [];
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
    _debounce?.cancel();
    _search.dispose();
    Session.instance.dataRevision.removeListener(_silentReload);
    super.dispose();
  }

  void _silentReload() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    final q = _search.text.trim();
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final users = await fetchUsers(q: q);
      if (!mounted || q != _search.text.trim())
        return; // a newer search is in flight
      setState(() {
        _users = users;
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

  void _onChanged(String _) {
    setState(() {}); // shows / hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = Session.instance.userId;

    Widget list;
    if (_loading && _users.isEmpty) {
      list = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _users.isEmpty) {
      list = ErrorView(message: _error!, onRetry: _load);
    } else if (_users.isEmpty) {
      list = EmptyView(
        icon: Icons.search_rounded,
        title: 'No users found',
        subtitle: 'Nobody matches “${_search.text.trim()}”.',
      );
    } else {
      list = RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _users.length,
          itemBuilder: (context, i) {
            final u = _users[i];
            return InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      username: u.username,
                      size: 52,
                      ring: u.postsCount > 0,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                              if (u.id == me) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (u.bio ?? '').isNotEmpty
                                ? u.bio!
                                : '${u.postsCount} ${u.postsCount == 1 ? 'post' : 'posts'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Discover',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              decoration:
                  fieldDecoration(
                    context,
                    hint: 'Search people',
                    icon: Icons.search_rounded,
                    suffix: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              _onChanged('');
                            },
                          ),
                  ).copyWith(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
            ),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}
