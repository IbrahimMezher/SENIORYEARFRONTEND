import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class PaymentService {
  final _api = ApiService();

  Future<Map<String, dynamic>> checkout({
    required String paymentMethod,
    String? street, String? city, String? state,
    String? postalCode, String? country,
    int? addressId, String? fieldValues,
  }) async {
    final body = <String, dynamic>{'paymentMethod': paymentMethod};
    if (fieldValues != null) body['fieldValues'] = fieldValues;
    if (addressId != null) {
      body['addressId'] = addressId;
    } else {
      body['street'] = street; body['city'] = city;
      body['state'] = state ?? ''; body['postalCode'] = postalCode;
      body['country'] = country;
    }
    final r = await _api.post('/checkout', body);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_api.parseError(r));
  }
}
