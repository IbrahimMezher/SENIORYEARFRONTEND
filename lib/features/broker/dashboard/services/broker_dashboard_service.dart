import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class BrokerDashboardService {
  final _api = ApiService();

  Future<Map<String, dynamic>> getBrokerDetails() async {
    final r = await _api.get('/brokers/brokerinfo');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load broker info');
  }

  Future<List<dynamic>> getBrokerTransactions() async {
    final r = await _api.get('/transactions/broker');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load transactions');
  }

  Future<String> getUserName(int userId) async {
    final r = await _api.get('/users/$userId');
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      return data['fullName']?.toString() ?? 'Customer';
    }
    return 'Customer';
  }

}
