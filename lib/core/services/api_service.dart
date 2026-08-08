import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class ApiService {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Uri _uri(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final path = url.startsWith('/') ? url : '/$url';
    return Uri.parse('$base$path');
  }

  String assetUrl(String? value) {
    final path = value?.trim() ?? '';
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }

  Map<String, String> _headers(String? token, {bool auth = true}) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Accept-Charset': 'UTF-8',
        if (auth && token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String url, {bool auth = true}) async {
    final token = auth ? await SecureStorageService.getToken() : null;
    final response = await http.get(
      _uri(url),
      headers: _headers(token, auth: auth),
    );

    if (auth && response.statusCode == 401) {
      await SecureStorageService.clearSession();
    }

    return response;
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final token = auth ? await SecureStorageService.getToken() : null;
    final response = await http.post(
      _uri(url),
      headers: _headers(token, auth: auth),
      body: jsonEncode(body),
    );

    if (auth && response.statusCode == 401) {
      await SecureStorageService.clearSession();
    }

    return response;
  }

  Future<http.Response> put(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final token = auth ? await SecureStorageService.getToken() : null;
    final response = await http.put(
      _uri(url),
      headers: _headers(token, auth: auth),
      body: jsonEncode(body),
    );

    if (auth && response.statusCode == 401) {
      await SecureStorageService.clearSession();
    }

    return response;
  }

  Future<http.Response> delete(String url, {bool auth = true}) async {
    final token = auth ? await SecureStorageService.getToken() : null;
    final response = await http.delete(
      _uri(url),
      headers: _headers(token, auth: auth),
    );

    if (auth && response.statusCode == 401) {
      await SecureStorageService.clearSession();
    }

    return response;
  }

  Future<http.Response> uploadBytes(
    String url, {
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    bool auth = true,
  }) async {
    final token = auth ? await SecureStorageService.getToken() : null;
    final request = http.MultipartRequest('POST', _uri(url));
    request.headers.addAll({
      'Accept': 'application/json',
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    });
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
      contentType: _contentTypeFor(filename),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (auth && response.statusCode == 401) {
      await SecureStorageService.clearSession();
    }

    return response;
  }

  void ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(parseError(response));
  }

  dynamic decode(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String parseError(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['message']?.toString() ??
          body['error']?.toString() ??
          response.body;
    } catch (_) {
      return response.body;
    }
  }

  MediaType? _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return null;
  }
}
