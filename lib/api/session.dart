import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the logged-in user and the JWT, and remembers them between launches.
class Session extends ChangeNotifier {
  Session._();
  static final Session instance = Session._();

  String? token;
  int? userId;
  String? username;

  bool get isLoggedIn => token != null && userId != null;

  /// Bumped whenever something is created / edited / deleted so every visible
  /// screen (feed, profile, detail) can quietly reload itself.
  final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);
  void bump() => dataRevision.value++;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      userId = prefs.getInt('userId');
      username = prefs.getString('username');
    } catch (_) {
      // storage unavailable: just start logged out
    }
  }

  Future<void> signIn({
    required String token,
    required int userId,
    required String username,
  }) async {
    this.token = token;
    this.userId = userId;
    this.username = username;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('userId', userId);
      await prefs.setString('username', username);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> signOut() async {
    token = null;
    userId = null;
    username = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('username');
    } catch (_) {}
    notifyListeners();
  }
}
