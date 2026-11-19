import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:instagram_ui/api/config.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

String _detail(http.Response res) {
  try {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final detail = body is Map ? body['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final first = detail.first as Map;
      final loc = first['loc'];
      final field = loc is List && loc.isNotEmpty ? '${loc.last}' : '';
      final msg = '${first['msg'] ?? 'Invalid input'}';
      return field.isEmpty || field == 'body' ? msg : '$field: $msg';
    }
  } catch (_) {}
  return 'Request failed (${res.statusCode})';
}

Future<dynamic> _request(
  String method,
  String path, {
  Map<String, String>? query,
  Object? json,
  Map<String, String>? form,
  bool auth = true,
}) async {
  final uri = Uri.http(kApiHost, path, query);
  final token = Session.instance.token;

  http.Response res;
  try {
    final req = http.Request(method, uri);
    req.headers['Accept'] = 'application/json';
    if (auth && token != null) req.headers['Authorization'] = 'Bearer $token';
    if (json != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(json);
    } else if (form != null) {
      req.bodyFields = form;
    }
    final streamed = await req.send().timeout(const Duration(seconds: 20));
    res = await http.Response.fromStream(streamed);
  } catch (_) {
    throw ApiException(
      'Can’t reach the server. Make sure the API is running at $kApiHost.',
    );
  }

  if (res.statusCode == 401 && auth && token != null) {
    await Session.instance.signOut();
    throw ApiException(
      'Your session expired. Please sign in again.',
      statusCode: 401,
    );
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(_detail(res), statusCode: res.statusCode);
  }
  if (res.statusCode == 204 || res.body.isEmpty) return null;
  return jsonDecode(utf8.decode(res.bodyBytes));
}

List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) f) {
  return (data as List).map((x) => f(x as Map<String, dynamic>)).toList();
}

// ------------------------------------------------------------------ auth
Future<void> login(String username, String password) async {
  final data = await _request(
    'POST',
    'token',
    form: {'username': username.trim(), 'password': password},
    auth: false,
  ) as Map<String, dynamic>;
  await Session.instance.signIn(
    token: data['access_token'] as String,
    userId: (data['userID'] as num).toInt(),
    username: data['username'] as String,
  );
}

Future<void> register(String username, String email, String password) async {
  await _request(
    'POST',
    'user',
    json: {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    },
    auth: false,
  );
  await login(username, password);
}

// ----------------------------------------------------------------- users
Future<List<User>> fetchUsers({String q = ''}) async {
  final data = await _request(
    'GET',
    'user',
    query: q.trim().isEmpty ? null : {'q': q.trim()},
  );
  return _list(data, User.fromJson);
}

Future<User> fetchUser(int id) async {
  final data = await _request('GET', 'user/$id');
  return User.fromJson(data as Map<String, dynamic>);
}

/// Your own profile (includes the e-mail address).
Future<User> fetchMe() async {
  final data = await _request('GET', 'user/me');
  return User.fromJson(data as Map<String, dynamic>);
}

Future<User> updateMe({String? bio, String? email}) async {
  final body = <String, dynamic>{};
  if (bio != null) body['bio'] = bio;
  if (email != null) body['email'] = email;
  final data = await _request('PATCH', 'user/me', json: body);
  return User.fromJson(data as Map<String, dynamic>);
}

// ----------------------------------------------------------------- posts
Future<List<Posts>> fetchAllPosts() async {
  final data = await _request('GET', 'post/');
  return _list(data, Posts.fromJson);
}

Future<Posts> fetchPost(int id) async {
  final data = await _request('GET', 'post/$id');
  return Posts.fromJson(data as Map<String, dynamic>);
}

Future<List<Posts>> fetchPostsByUser(int userId) async {
  final data = await _request(
    'GET',
    'post/user_posts',
    query: {'user_id': '$userId'},
  );
  return _list(data, Posts.fromJson);
}

Future<Posts> createPost(String imageUrl, String caption) async {
  final data = await _request(
    'POST',
    'post/create_post',
    json: {
      'image_url': imageUrl.trim(),
      'image_url_type': 'url',
      'caption': caption.trim(),
    },
  );
  return Posts.fromJson(data as Map<String, dynamic>);
}

Future<Posts> updatePost(int id, String caption) async {
  final data = await _request(
    'PATCH',
    'post/update_caption/$id',
    json: {'caption': caption},
  );
  return Posts.fromJson(data as Map<String, dynamic>);
}

Future<void> deletePost(int id) async {
  await _request('DELETE', 'post/delete_post/$id');
}

// -------------------------------------------------------------- comments
Future<List<Comment>> fetchComments(int postId) async {
  final data = await _request('GET', 'comment/$postId');
  return _list(data, Comment.fromJson);
}

Future<Comment> createComment(int postId, String text) async {
  final data = await _request(
    'POST',
    'comment/create_comment',
    json: {'post_id': postId, 'text': text},
  );
  return Comment.fromJson(data as Map<String, dynamic>);
}

Future<Comment> updateComment(int id, String text) async {
  final data = await _request(
    'PATCH',
    'comment/update_comment/$id',
    json: {'text': text},
  );
  return Comment.fromJson(data as Map<String, dynamic>);
}

Future<void> deleteComment(int id) async {
  await _request('DELETE', 'comment/delete_comment', query: {'id': '$id'});
}
