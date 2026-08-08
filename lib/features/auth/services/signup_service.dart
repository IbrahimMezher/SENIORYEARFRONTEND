import 'dart:convert';
import 'dart:developer' as dev;
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';

class SignupService {
  final _api = ApiService();

  Future<void> userSignup({
    required String fullName, required String email,
    required String password, required String confirm,
    required String phoneNumber, required int countryId,
    required bool acceptedTerms,
  }) async {
    final r = await _api.post(
      '/users/signup',
      {'fullName': fullName, 'email': email, 'password': password,
        'confirm': confirm, 'phoneNumber': phoneNumber, 'countryId': countryId,
        'acceptedTerms': acceptedTerms},
      auth: false,
    );
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    await SecureStorageService.saveSession(
      token: data['accessToken'] ?? '', role: data['role'] ?? '',
      fullName: data['fullName'] ?? fullName, email: data['email'] ?? email,
      status: data['status'] ?? '',
    );
  }

  Future<void> brokerSignup({
    required String fullName, required String email,
    required String password, required String confirm,
    required String phoneNumber, required int countryId,
    required String companyName, required String licenseNumber,
    required String address, required String taxId,
    String? logoUrl, String? websiteUrl,
    required String idFrontUrl, required String idBackUrl,
    required bool acceptedTerms,
  }) async {
    final r = await _api.post(
      '/brokers/signup',
      {
        'fullName': fullName, 'email': email, 'password': password,
        'confirm': confirm, 'phoneNumber': phoneNumber, 'countryId': countryId,
        'companyName': companyName, 'licenseNumber': licenseNumber,
        'address': address, 'taxId': taxId,
        'websiteUrl': websiteUrl ?? '', 'logoUrl': logoUrl ?? '',
        'idFrontUrl': idFrontUrl, 'idBackUrl': idBackUrl,
        'acceptedTerms': acceptedTerms,
      },
      auth: false,
    );
    _api.ensureSuccess(r);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    await SecureStorageService.saveSession(
      token: data['accessToken'] ?? '', role: data['role'] ?? '',
      fullName: data['fullName'] ?? fullName, email: data['email'] ?? email,
      status: data['status'] ?? '',
    );
  }

  Future<List<dynamic>> getAllCountries() async {
    dev.log('[Countries] baseUrl = "${_api.baseUrl}"');
    dev.log('[Countries] GET ${_api.baseUrl}/countries/getAllCountries');
    final r = await _api.get('/countries/getAllCountries', auth: false);
    dev.log('[Countries] status = ${r.statusCode}');
    dev.log('[Countries] body   = ${r.body}');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception('Failed to load countries: ${r.statusCode} ${r.body}');
  }
}
