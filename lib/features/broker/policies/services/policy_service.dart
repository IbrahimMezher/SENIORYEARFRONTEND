import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class PolicyService {
  final _api = ApiService();

  Future<List<dynamic>> getMyPolicies() async {
    final r = await _api.get('/policies/broker');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load policies');
  }

  Future<List<dynamic>> getBrokerReviews() async {
    final r = await _api.get('/reviews/broker');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllCategories() async {
    final r = await _api.get('/policycategories');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load categories');
  }

  Future<List<dynamic>> getCategoryFields(int categoryId) async {
    final r = await _api.get('/policycategories/$categoryId/fields');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllCountries() async {
    final r = await _api.get('/countries/getAllCountries');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load countries');
  }

  Future<List<dynamic>> getAllPolicyDurations() async {
    final r = await _api.get('/policyduration');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load durations');
  }

  Future<List<dynamic>> getAllExclusionTypes() async {
    final r = await _api.get('/exclusiontypes');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load exclusions');
  }

  Future<String> createPolicy({
    required int categoryId,
    required String policyName,
    required String description,
    required int policyDurationId,
    required List<int> exclusionTypeIds,
    List<int> benefitIds = const [],
    List<int> inclusionIds = const [],
    required List<Map<String, dynamic>> coverageTiers,
    String status = 'DRAFT',
    int? waitingPeriodDays,
    String? deductiblePerClaim,
    String? deductiblePerYear,
    int? maxClaimsPerYear,
    String? maxClaimAmount,
    int? minAge,
    int? maxAge,
    int? claimProcessingDays,
    String? documentUrl,
    int? countryId,
    String? deliveryPrice,
  }) async {
    final body = <String, dynamic>{
      'categoryId': categoryId,
      'policyName': policyName,
      'description': description,
      'policyDurationId': policyDurationId,
      'exclusionTypeIds': exclusionTypeIds,
      'benefitIds': benefitIds,
      'inclusionIds': inclusionIds,
      'coverageTiers': coverageTiers,
      'status': status,
      if (waitingPeriodDays != null) 'waitingPeriodDays': waitingPeriodDays,
      if (deductiblePerClaim != null) 'deductiblePerClaim': deductiblePerClaim,
      if (deductiblePerYear != null) 'deductiblePerYear': deductiblePerYear,
      if (maxClaimsPerYear != null) 'maxClaimsPerYear': maxClaimsPerYear,
      if (maxClaimAmount != null) 'maxClaimAmount': maxClaimAmount,
      if (minAge != null) 'minAge': minAge,
      if (maxAge != null) 'maxAge': maxAge,
      if (claimProcessingDays != null) 'claimProcessingDays': claimProcessingDays,
      if (documentUrl != null) 'documentUrl': documentUrl,
      if (countryId != null) 'countryId': countryId,
      if (deliveryPrice != null) 'deliveryPrice': deliveryPrice,
    };
    final r = await _api.post('/policies/create', body);
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> editPolicy({required int id, Map<String, dynamic>? updates}) async {
    final r = await _api.put('/policies/broker/$id', updates ?? {});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllBenefits() async {
    final r = await _api.get('/benefits');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load benefits');
  }

  Future<List<dynamic>> getAllInclusions() async {
    final r = await _api.get('/inclusions');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load inclusions');
  }
}
