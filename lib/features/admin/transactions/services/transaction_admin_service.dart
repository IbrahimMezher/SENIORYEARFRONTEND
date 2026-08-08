import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class TransactionAdminService {
  final _api = ApiService();

  Future<List<dynamic>> getAllTransactions() async {
    final r = await _api.get('/admin/transactions');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<String> updatePaymentStatus(int txId, String status) async {
    final r = await _api.put('/admin/transactions/$txId/status', {'paymentStatus': status});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }
}
