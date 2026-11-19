import 'package:flutter/material.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/screens/add_post.dart';
import 'package:instagram_ui/screens/explore_screen.dart';
import 'package:instagram_ui/screens/feed_screen.dart';
import 'package:instagram_ui/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Navigation items: 0 home, 1 search, 2 add (opens a page), 3 profile
  int _nav = 0;

  int get _stackIndex => _nav == 3 ? 2 : _nav;

  Future<void> _onSelect(int i) async {
    if (i == 2) {
      final posted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AddPostScreen(),
        ),
      );
      if (posted == true && mounted) setState(() => _nav = 0);
      return;
    }
    setState(() => _nav = i);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          const FeedScreen(),
          const ExploreScreen(),
          ProfileScreen(userId: Session.instance.userId!, embedded: true),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _nav,
          onDestinationSelected: _onSelect,
          height: 62,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 28),
              selectedIcon: Icon(Icons.home_rounded, size: 28),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded, size: 28),
              selectedIcon: Icon(Icons.manage_search_rounded, size: 30),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_box_outlined, size: 28),
              label: 'New post',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined, size: 28),
              selectedIcon: Icon(Icons.account_circle_rounded, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
