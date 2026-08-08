import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class ClaimsAdminService {
  final _api = ApiService();

  Future<List<dynamic>> getAllClaims() async {
    final r = await _api.get('/admin/claims');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> updateClaimStatus(int claimId, String status) async {
    final r = await _api.put('/admin/claims/$claimId/status', {'claimStatus': status});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }
}
