import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class PolicyBrowseService {
  final _api = ApiService();

  Future<List<dynamic>> getAllPolicies({int? countryId}) async {
    final url = countryId != null
        ? '/policies/allPolicies?countryId=$countryId'
        : '/policies/allPolicies';
    final r = await _api.get(url);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load policies');
  }

  Future<List<dynamic>> getPoliciesByBroker(int brokerId) async {
    final r = await _api.get('/policies/public/broker/$brokerId', auth: false);
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception('Failed to load broker policies');
  }

  Future<Map<String, dynamic>> getPolicyById(int id) async {
    final r = await _api.get('/policies/$id');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load policy');
  }

  Future<List<dynamic>> getAllCategories() async {
    final r = await _api.get('/policycategories');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load categories');
  }

  Future<List<dynamic>> getAllCountries() async {
    final r = await _api.get('/countries/getAllCountries', auth: false);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load countries');
  }

  Future<List<dynamic>> getActiveBrokers() async {
    final r = await _api.get('/brokers/public', auth: false);
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception('Failed to load brokers');
  }

  String assetUrl(String? value) {
    final path = value?.trim() ?? '';
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = _api.baseUrl.endsWith('/')
        ? _api.baseUrl.substring(0, _api.baseUrl.length - 1)
        : _api.baseUrl;
    return '$base${path.startsWith('/') ? path : '/$path'}';
  }

  Future<List<dynamic>> getCategoryFields(int categoryId) async {
    final r = await _api.get('/policycategories/$categoryId/fields');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    return [];
  }

  Future<List<dynamic>> getCoverageTiers(int policyId) async {
    final r = await _api.get('/coveragetiers/policy/$policyId');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load tiers');
  }
}
