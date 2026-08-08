import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class TransactionService {
  final _api = ApiService();

  Future<List<dynamic>> getMyTransactions() async {
    final r = await _api.get('/transactions/users');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_api.parseError(r));
  }
}
