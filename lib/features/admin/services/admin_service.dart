import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class AdminService {
  final _api = ApiService();

  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final r = await _api.post(
      '/admin/auth/login',
      {'email': email, 'password': password},
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
    );
    return data;
  }

  Future<Map<String, dynamic>> verify2FACode({
    required String email,
    required String code,
  }) async {
    final r = await _api.post(
      '/admin/auth/2fa/verify',
      {'email': email, 'code': code},
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
    );
    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _api.get('/admin/auth/me');
    _api.ensureSuccess(r);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<List<dynamic>> getAllUsers() async {
    final r = await _api.get('/admin/users');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getPendingBrokers() async {
    final r = await _api.get('/admin/users/brokers/pending');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<Map<String, dynamic>> getBrokerDetails(int userId) async {
    final r = await _api.get('/admin/users/brokers/$userId/details');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> updateBrokerStatus(int userId, String status) async {
    final r = await _api.put('/admin/users/brokers/$userId/status', {'status': status});
    _api.ensureSuccess(r);
    return r.body;
  }

  Future<String> deleteUser(int userId) async {
    final r = await _api.delete('/admin/users/$userId');
    _api.ensureSuccess(r);
    return r.body;
  }

  Future<List<dynamic>> getAllTransactions() async {
    final r = await _api.get('/admin/transactions');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllClaims() async {
    final r = await _api.get('/admin/claims');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> updateClaimStatus(int claimId, String status) async {
    final r = await _api.put('/admin/claims/$claimId/status', {'claimStatus': status});
    _api.ensureSuccess(r);
    return r.body;
  }
}
