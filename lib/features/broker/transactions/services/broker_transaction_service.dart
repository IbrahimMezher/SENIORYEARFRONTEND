import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class BrokerTransactionService {
  final _api = ApiService();

  Future<List<dynamic>> getBrokerTransactions() async {
    final r = await _api.get('/transactions/broker');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load transactions');
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
}
