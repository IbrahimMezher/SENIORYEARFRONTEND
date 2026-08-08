import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class BrokerAdminService {
  final _api = ApiService();

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
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllBrokers() async {
    final r = await _api.get('/admin/users');
    if (r.statusCode == 200) {
      final all = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      return all.where((u) => u['role']?['name'] == 'broker').toList();
    }
    throw Exception(_api.parseError(r));
  }

  Future<String> approveBroker(Map<String, dynamic> user) async {
    final id = user['userId'] ?? user['id'];
    return updateBrokerStatus(id is int ? id : int.parse(id.toString()), 'ACTIVE');
  }

  Future<String> rejectBroker(Map<String, dynamic> user) async {
    final id = user['userId'] ?? user['id'];
    return updateBrokerStatus(id is int ? id : int.parse(id.toString()), 'SUSPENDED');
  }

}
