import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:fluttertest/features/auth/services/verify_service.dart';

class TwoFaService {
  final _api = ApiService();

  Future<void> send2FACode(String email, {String? method}) async {
    final r = await _api.post(
      '/auth/2fa/send',
      {
        'email': email,
        if (method != null) 'method': method,
      },
      auth: false,
    );
    _api.ensureSuccess(r);
  }

  Future<void> sendAdmin2FACode(String email, {String? method}) async {
    final r = await _api.post(
      '/admin/auth/2fa/send',
      {
        'email': email,
        if (method != null) 'method': method,
      },
      auth: false,
    );
    _api.ensureSuccess(r);
  }

  Future<Map<String, dynamic>> verify2FACode(
      {required String email, required String code, String? method}) async {
    final r = await _api.post(
      '/auth/2fa/verify',
      {'email': email, 'code': code, if (method != null) 'method': method},
      auth: false,
    );
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    await SecureStorageService.saveSession(
      token: data['accessToken'] ?? '',
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
    );
    await refreshStoredAuthStatus();
    return data;
  }

  Future<Map<String, dynamic>> verifyAdmin2FACode(
      {required String email, required String code, String? method}) async {
    final r = await _api.post(
      '/admin/auth/2fa/verify',
      {'email': email, 'code': code, if (method != null) 'method': method},
      auth: false,
    );
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    await SecureStorageService.saveSession(
      token: data['accessToken'] ?? '',
      role: data['role'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      status: 'ACTIVE',
      emailVerified: true,
      phoneVerified: true,
      twoFaEnabled: true,
      twoFaMethod: method ?? 'email',
    );
    await refreshStoredAuthStatus();
    return data;
  }

  Future<void> setup2FA(String method) async {
    final r = await _api.post('/auth/2fa/setup', {'method': method});
    _api.ensureSuccess(r);
    await SecureStorageService.write('twoFaEnabled', 'true');
    await SecureStorageService.write('twoFaMethod', method);
  }

  Future<void> disable2FA() async {
    final r = await _api.post('/auth/2fa/disable', {});
    _api.ensureSuccess(r);
    await SecureStorageService.write('twoFaEnabled', 'false');
    await SecureStorageService.write('twoFaMethod', '');
  }
}
