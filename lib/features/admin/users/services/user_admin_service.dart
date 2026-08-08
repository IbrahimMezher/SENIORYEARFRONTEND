import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class UserAdminService {
  final _api = ApiService();

  Future<List<dynamic>> getAllUsers() async {
    final r = await _api.get('/admin/users');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteUser(int userId) async {
    final r = await _api.delete('/admin/users/$userId');
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> createAdmin({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirm,
    required String phoneNumber,
    required int countryId,
    required String countryName,
    required String countryCode,
  }) async {
    final r = await _api.post('/admin/auth/register', {
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'confirm': confirm,
      'phoneNumber': phoneNumber,
      'countryId': countryId,
      'country_id': countryId,
      'countryName': countryName,
      'country_name': countryName,
      'countryCode': countryCode,
      'country_code': countryCode,
    });
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }
}
