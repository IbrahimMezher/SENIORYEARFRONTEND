import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class WishlistService {
  static final _api = ApiService();

  static Set<int>? _cache;

  static Future<Set<int>> getAll({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    try {
      final r = await _api.get('/wishlist/ids');
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        _cache = list.map((e) => (e as num).toInt()).toSet();
        return _cache!;
      }
    } catch (_) {}
    _cache ??= {};
    return _cache!;
  }

  static Future<List<dynamic>> getWishlist() async {
    final r = await _api.get('/wishlist');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  static Future<bool> isFavourite(int policyId) async {
    final ids = await getAll();
    return ids.contains(policyId);
  }

  static Future<bool> toggle(int policyId) async {
    final r = await _api.post('/wishlist/toggle', {'policyId': policyId});
    if (r.statusCode == 200) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final wishlisted = body['wishlisted'] == true;
      _cache ??= {};
      if (wishlisted) {
        _cache!.add(policyId);
      } else {
        _cache!.remove(policyId);
      }
      return wishlisted;
    }
    throw Exception(_api.parseError(r));
  }

  static void clearCache() => _cache = null;
}
