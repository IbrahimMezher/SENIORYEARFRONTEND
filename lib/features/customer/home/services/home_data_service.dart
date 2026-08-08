import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class HomeDataService {
  final _api = ApiService();

  Future<String?> getFullName() async => await SecureStorageService.getFullName();

  Future<List<dynamic>> getFeaturedPolicies() async {
    final r = await _api.get('/policies/allPolicies');
    if (r.statusCode == 200) return jsonDecode(r.body);
    return [];
  }

  Future<List<dynamic>> getMyTransactions() async {
    final r = await _api.get('/transactions/users');
    if (r.statusCode == 200) return jsonDecode(r.body);
    return [];
  }

  Future<List<dynamic>> getMyClaims() async {
    final r = await _api.get('/claims/user/me');
    if (r.statusCode == 200) return jsonDecode(r.body);
    return [];
  }
}
