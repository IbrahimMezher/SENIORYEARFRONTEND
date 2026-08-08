import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class AccountActionService {
  final _api = ApiService();

  Future<String> requestActionCode(String action) async {
    final r = await _api.post(
        '/auth/account/request-action', {'action': action});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }

  Future<String> confirmAction(String code) async {
    final r =
        await _api.post('/auth/account/confirm-action', {'code': code});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }
}
