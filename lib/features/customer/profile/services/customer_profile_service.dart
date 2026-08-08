import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class CustomerProfileService {
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

  Future<Map<String, dynamic>> getSession() async {
    return {
      'fullName': await SecureStorageService.getFullName() ?? '',
      'email': await SecureStorageService.getEmail() ?? '',
      'role': await SecureStorageService.getRole() ?? '',
      'twoFaEnabled': await SecureStorageService.isTwoFaEnabled(),
      'twoFaMethod': await SecureStorageService.getTwoFaMethod() ?? '',
    };
  }

  Future<void> changePassword({
    required String current,
    required String newPwd,
    required String confirm,
  }) async {
    final r = await _api.post('/auth/resetpassword', {
      'Password': current,
      'NewPassword': newPwd,
      'Confirm': confirm,
    });
    _check(r);
  }

  Future<void> setup2FA(String method) async {
    final r = await _api.post('/auth/2fa/setup', {'method': method});
    _check(r);
    await SecureStorageService.write('twoFaEnabled', 'true');
    await SecureStorageService.write('twoFaMethod', method);
  }

  Future<Map<String, dynamic>> get2FAStatus() async {
    final r = await _api.get('/auth/2fa/status');
    _check(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    await SecureStorageService.write(
        'twoFaEnabled', (data['twoFaEnabled'] == true).toString());
    await SecureStorageService.write(
        'twoFaMethod', data['twoFaMethod']?.toString() ?? '');
    await SecureStorageService.write(
        'emailVerified', (data['emailVerified'] == true).toString());
    await SecureStorageService.write(
        'phoneVerified', (data['phoneVerified'] == true).toString());
    return data;
  }

  Future<void> disable2FA() async {
    final r = await _api.post('/auth/2fa/disable', {});
    _check(r);
    await SecureStorageService.write('twoFaEnabled', 'false');
    await SecureStorageService.write('twoFaMethod', '');
  }

  Future<Map<String, dynamic>> getPrivacy() async {
    final r = await _api.get('/auth/privacy');
    _check(r);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<void> updatePrivacy(
      {bool? profileVisible, bool? contactVisible}) async {
    final body = <String, dynamic>{};
    if (profileVisible != null) body['profileVisible'] = profileVisible;
    if (contactVisible != null) body['contactVisible'] = contactVisible;
    final r = await _api.post('/auth/privacy', body);
    _check(r);
  }
}
