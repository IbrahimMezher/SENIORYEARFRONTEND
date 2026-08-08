import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class OtpService {
  final _api = ApiService();

  Future<void> sendOtp() async {
    final r = await _api.post('/auth/get_otp', {});
    _api.ensureSuccess(r);
  }

  Future<void> verifyEmailOtp(String otp) async {
    final r = await _api.post('/auth/verify_otp', {'otp': otp});
    _api.ensureSuccess(r);
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    final r = await _api.post('/auth/send-phone-otp', {'phoneNumber': phoneNumber});
    _api.ensureSuccess(r);
  }

  Future<void> verifyPhoneOtp({required String phoneNumber, required String code}) async {
    final r = await _api.post('/auth/verify-phone-otp', {'phoneNumber': phoneNumber, 'code': code});
    _api.ensureSuccess(r);
  }

  Future<void> changeEmail(String newEmail) async {
    final r = await _api.post('/auth/change-email', {'email': newEmail});
    _api.ensureSuccess(r);
    try {
      final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final newToken = data['accessToken']?.toString();
      final returnedEmail = data['email']?.toString() ?? newEmail;
      if (newToken != null && newToken.isNotEmpty) {
        await SecureStorageService.write('token', newToken);
      }
      await SecureStorageService.write('email', returnedEmail);
      await SecureStorageService.write('emailVerified', 'false');
    } catch (_) {}
  }
}
