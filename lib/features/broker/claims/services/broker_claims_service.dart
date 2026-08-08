import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class BrokerClaimsService {
  final _api = ApiService();

  Future<List<dynamic>> getAllClaims() async {
    final r = await _api.get('/broker/claims');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getBrokerTransactions() async {
    final r = await _api.get('/transactions/broker');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> updateClaimStatus({
    required int claimId,
    required String status,
  }) async {
    final r = await _api.put('/broker/claims/$claimId/status', {'claimStatus': status});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> approveTransaction(int transactionId) async {
    final r = await _api.put('/transactions/$transactionId/broker-approve', {});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> rejectTransaction(int transactionId) async {
    final r = await _api.put('/transactions/$transactionId/broker-reject', {});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<void> approveClaim(dynamic claimId) async {
    final r = await _api.put('/broker/claims/$claimId/approve', {});
    if (r.statusCode != 200) throw Exception(_api.parseError(r));
  }

  Future<void> rejectClaim(dynamic claimId) async {
    final r = await _api.put('/broker/claims/$claimId/reject', {});
    if (r.statusCode != 200) throw Exception(_api.parseError(r));
  }
}
