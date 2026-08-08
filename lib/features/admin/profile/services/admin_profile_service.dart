import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class AdminProfileService {
  final _api = ApiService();

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _api.get('/admin/auth/me');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<Map<String, dynamic>> getAdminProfile() => getProfile();
}
