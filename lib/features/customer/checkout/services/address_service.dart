import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class AddressService {
  final _api = ApiService();

  Future<List<dynamic>> getMyAddresses() async {
    final r = await _api.get('/addresses');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load addresses');
  }

  Future<Map<String, dynamic>> addAddress({
    required String fullName, required String phoneNumber,
    required String street, required String city,
    String? state, required String postalCode, required String country,
    bool isDefault = false,
  }) async {
    final r = await _api.post('/addresses', {
      'fullName': fullName, 'phoneNumber': phoneNumber,
      'street': street, 'city': city, 'state': state ?? '',
      'postalCode': postalCode, 'country': country, 'isDefault': isDefault,
    });
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_api.parseError(r));
  }
}
