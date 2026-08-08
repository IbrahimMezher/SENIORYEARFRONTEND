import 'package:fluttertest/core/services/api_service.dart';

class CartBrowseService {
  final _api = ApiService();

  Future<String> addToCart({
    required int policyId,
    required int coverageTierId,
    Map<String, String>? extraFields,
  }) async {
    final body = <String, dynamic>{
      'policyId': policyId,
      'coverageTierId': coverageTierId,
      if (extraFields != null && extraFields.isNotEmpty) 'extraFields': extraFields,
    };
    final r = await _api.post('/cart/add', body);
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }
}
