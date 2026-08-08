import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class LoginService {
  final _api = ApiService();

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final r = await _api.post(
      '/users/login',
      {'email': email, 'password': password},
      auth: false,
    );
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

    final token = (data['accessToken'] ?? '').toString();
    if (data['requiresTwoFa'] == true || token.isEmpty) {
      return data;
    }
    await SecureStorageService.saveSession(
      token: token,
      role: data['role'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      status: data['status'] ?? '',
      emailVerified:
          data['email_verified'] == true || data['emailVerified'] == true,
      phoneVerified:
          data['phone_verified'] == true || data['phoneVerified'] == true,
      twoFaEnabled: data['twoFaEnabled'] == true,
      twoFaMethod: data['twoFaMethod'] ?? '',
      countryId: data['countryId'] is int
          ? data['countryId']
          : int.tryParse('${data['countryId'] ?? ''}'),
    );
    return data;
  }

  Future<Map<String, dynamic>> adminLogin(
      {required String email, required String password}) async {
    final r = await _api.post(
      '/admin/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

    return data;
  }

  Future<void> logout() async => await SecureStorageService.clearSession();

  Future<String?> getSavedToken() async =>
      await SecureStorageService.getToken();
  Future<String?> getSavedRole() async => await SecureStorageService.getRole();

  Future<String> refreshStatus() async {
    final r = await _api.get('/auth/status');
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';
    await SecureStorageService.write('status', status);
    return status;
  }
}
