import 'dart:convert';
import 'package:http/http.dart' as http;

class WebDavService {
  static const String _fixedFileName = 'backup-otpauth.flauth';

  /// Performs a HEAD request to get the last modified time of the backup file.
  static Future<String?> fetchLastModified(Map<String, String> config) async {
    final paths = getNormalizedPaths(config);
    final fullUrl = '${paths['baseUrl']}${paths['remotePath']}$_fixedFileName';
    final basicAuth = _getAuthHeader(config);

    try {
      final response = await http.head(
        Uri.parse(fullUrl),
        headers: {'Authorization': basicAuth},
      );
      if (response.statusCode == 200) {
        return response.headers['last-modified'];
      }
    } catch (_) {}
    return null;
  }

  /// Uploads content to WebDAV.
  static Future<http.Response> upload(
    Map<String, String> config,
    String content,
  ) async {
    final paths = getNormalizedPaths(config);
    final fullUrl = '${paths['baseUrl']}${paths['remotePath']}$_fixedFileName';
    final basicAuth = _getAuthHeader(config);

    return await http.put(
      Uri.parse(fullUrl),
      headers: {'Authorization': basicAuth, 'Content-Type': 'text/plain'},
      body: content,
    );
  }

  /// Downloads content from WebDAV.
  static Future<http.Response> download(Map<String, String> config) async {
    final paths = getNormalizedPaths(config);
    final fullUrl = '${paths['baseUrl']}${paths['remotePath']}$_fixedFileName';
    final basicAuth = _getAuthHeader(config);

    return await http.get(
      Uri.parse(fullUrl),
      headers: {'Authorization': basicAuth},
    );
  }

  /// Normalizes paths for WebDAV.
  static Map<String, String> getNormalizedPaths(Map<String, String> config) {
    String url = config['url'] ?? '';
    if (url.isNotEmpty && !url.endsWith('/')) url += '/';

    String path = config['path'] ?? '';
    if (path.startsWith('/')) path = path.substring(1);
    if (path.isNotEmpty && !path.endsWith('/')) path += '/';

    return {'baseUrl': url, 'remotePath': path};
  }

  static String _getAuthHeader(Map<String, String> config) {
    final user = config['username'] ?? '';
    final pass = config['password'] ?? '';
    return 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
  }

  static String get fileName => _fixedFileName;
}
