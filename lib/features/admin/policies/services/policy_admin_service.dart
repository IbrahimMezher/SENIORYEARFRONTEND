import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class PolicyAdminService {
  final _api = ApiService();

  Future<List<dynamic>> getPendingPolicies() async {
    final r = await _api.get('/admin/policies/pending');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> approvePolicy(int policyId) async {
    final r = await _api.put('/admin/policies/$policyId/approve', {});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }

  Future<String> rejectPolicy(int policyId, String reason) async {
    final r = await _api
        .put('/admin/policies/$policyId/reject', {'reason': reason});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }
}
