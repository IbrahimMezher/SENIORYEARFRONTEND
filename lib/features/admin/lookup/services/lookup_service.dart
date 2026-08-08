import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class LookupService {
  final _api = ApiService();

  Future<List<dynamic>> getAllCategories() async {
    final r = await _api.get('/policycategories');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load categories');
  }

  Future<List<dynamic>> getCategoryFields(int categoryId) async {
    final r = await _api.get('/policycategories/$categoryId/fields');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    return [];
  }

  Future<String> addCategoryField({
    required int categoryId,
    required String fieldName,
    required String fieldLabel,
    required String fieldType,
    required bool isRequired,
    String? fieldOptions,
    int? displayOrder,
  }) async {
    final r = await _api.post('/policycategories/$categoryId/fields', {
      'fieldName': fieldName,
      'fieldLabel': fieldLabel,
      'fieldType': fieldType,
      'isRequired': isRequired,
      if (fieldOptions != null && fieldOptions.trim().isNotEmpty)
        'fieldOptions': fieldOptions.trim(),
      if (displayOrder != null) 'displayOrder': displayOrder,
    });
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteCategory(int categoryId) async {
    final r = await _api.delete('/policycategories/$categoryId');
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

  Future<List<dynamic>> getAllExclusionTypes() async {
    final r = await _api.get('/exclusiontypes');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load exclusions');
  }

  Future<List<dynamic>> getAllPolicyDurations() async {
    final r = await _api.get('/policyduration');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load durations');
  }

  Future<String> createBenefit({required String title, required String description}) async {
    final r = await _api.post('/benefits', {'title': title, 'description': description});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteBenefit(int id) async {
    final r = await _api.delete('/benefits/$id');
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> createInclusion({required String name, required String description}) async {
    final r = await _api.post('/inclusions', {'name': name, 'description': description});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteInclusion(int id) async {
    final r = await _api.delete('/inclusions/$id');
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> createExclusionType({required String name, required String description}) async {
    final r = await _api.post('/exclusiontypes', {'name': name, 'description': description});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteExclusionType(int id) async {
    final r = await _api.delete('/exclusiontypes/$id');
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> createCategory({required String categoryName}) async {
    final r = await _api.post('/policycategories', {'categoryName': categoryName});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllDurations() async {
    final r = await _api.get('/policyduration');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_api.parseError(r));
  }

  Future<String> createDuration({required String label, required String duration}) async {
    final r = await _api.post('/policyduration', {'label': label, 'duration': duration});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteDuration(int id) async {
    final r = await _api.delete('/policyduration/$id');
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<List<dynamic>> getAllCountries() async {
    final r = await _api.get('/countries/getAllCountries');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_api.parseError(r));
  }

  Future<String> createCountry({required String countryName, required String currency, required String code, double taxPercentage = 0, double deliveryPrice = 0}) async {
    final r = await _api.post('/countries/details', {'countryName': countryName, 'currency': currency, 'code': code, 'taxPercentage': taxPercentage, 'deliveryPrice': deliveryPrice});
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

  Future<String> deleteCategoryField(int categoryId, int fieldId) async {
    final r = await _api.delete('/policycategories/$categoryId/fields/$fieldId');
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }

}
