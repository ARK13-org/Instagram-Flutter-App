import 'package:flutter/material.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/screens/auth_screen.dart';
import 'package:instagram_ui/screens/main_shell.dart';
import 'package:instagram_ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.instance.load();
  runApp(const ArkApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ArkApp extends StatefulWidget {
  const ArkApp({super.key});

  @override
  State<ArkApp> createState() => _ArkAppState();
}

class _ArkAppState extends State<ArkApp> {
  @override
  void initState() {
    super.initState();
    Session.instance.addListener(_onSession);
  }

  @override
  void dispose() {
    Session.instance.removeListener(_onSession);
    super.dispose();
  }

  // Signed out (or the token expired) while a detail page was open:
  // drop back to the root so the login screen is visible.
  void _onSession() {
    if (!Session.instance.isLoggedIn) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARK13',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) =>
          Session.instance.isLoggedIn ? const MainShell() : const AuthScreen(),
    );
  }
}
