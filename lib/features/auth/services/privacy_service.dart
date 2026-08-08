import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class PrivacyService {
  final _api = ApiService();

  void _check(dynamic r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    try {
      final b = jsonDecode(utf8.decode(r.bodyBytes));
      throw Exception(b['message'] ?? b['error'] ?? r.body);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(r.body);
    }
  }

  Future<Map<String, dynamic>> getPrivacy() async {
    final r = await _api.get('/auth/privacy');
    _check(r);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<void> updatePrivacy({bool? profileVisible, bool? contactVisible}) async {
    final body = <String, dynamic>{};
    if (profileVisible != null) body['profileVisible'] = profileVisible;
    if (contactVisible != null) body['contactVisible'] = contactVisible;
    final r = await _api.post('/auth/privacy', body);
    _check(r);
  }
}
