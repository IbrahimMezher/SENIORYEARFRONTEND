import 'package:fluttertest/core/services/api_service.dart';

class PasswordService {
  final _api = ApiService();

  Future<void> forgotPassword(String email) async {
    final r = await _api.post('/auth/forgot-password', {'email': email}, auth: false);
    _api.ensureSuccess(r);
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    final r = await _api.post(
      '/auth/reset-password',
      {'token': token, 'newPassword': newPassword},
      auth: false,
    );
    _api.ensureSuccess(r);
  }

  Future<void> changePassword({
    required String Password, required String NewPassword, required String Confirm,
  }) async {
    final r = await _api.post('/auth/resetpassword', {
      'Password': Password, 'NewPassword': NewPassword, 'Confirm': Confirm,
    });
    _api.ensureSuccess(r);
  }
}
