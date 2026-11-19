/// Where the FastAPI server lives.
///
/// Run with a different host without touching code:
///   flutter run --dart-define=API_HOST=10.0.2.2:8000     (Android emulator)
///   flutter run --dart-define=API_HOST=192.168.1.20:8000 (real phone, same Wi-Fi)
const String kApiHost = String.fromEnvironment(
  'API_HOST',
  defaultValue: '127.0.0.1:8000',
);

/// Posts can be stored as a full URL (`url`) or as a file uploaded to the
/// server (`uploaded`, e.g. "uploaded_file/photo_abc.jpg"). Both end up here.
String resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final name = url.split(RegExp(r'[\\/]')).last;
  return 'http://$kApiHost/files/$name';
}
