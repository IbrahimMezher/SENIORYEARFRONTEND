import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class ClaimFilingService {
  final _api = ApiService();

  Future<List<dynamic>> getMyClaims() async {
    final r = await _api.get('/claims/user/me');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_api.parseError(r));
  }

  Future<String> fileClaim({
    required int transactionId,
    required double claimAmount,
    required String remarks,
  }) async {
    final r = await _api.post('/claims/create', {
      'transactionId': transactionId,
      'claimAmount': claimAmount,
      'remarks': remarks,
    });
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }
}
