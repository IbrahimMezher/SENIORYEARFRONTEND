import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class DeliveryService {
  final _api = ApiService();

  Future<String> markShipped({
    required int transactionId,
    required String shipmentId,
    required String trackingUrl,
    String? carrierName,
  }) async {
    final r = await _api.put('/delivery/$transactionId/ship', {
      'shipmentId': shipmentId,
      'trackingUrl': trackingUrl,
      if (carrierName != null && carrierName.isNotEmpty)
        'carrierName': carrierName,
    });
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }

  Future<String> markPaid(int transactionId) async {
    final r = await _api.put('/delivery/$transactionId/paid', {});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }

  Future<String> markNotReceived(int transactionId) async {
    final r = await _api.put('/delivery/$transactionId/not-received', {});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }

  Future<String> markDelivered(int transactionId) async {
    final r = await _api.put('/delivery/$transactionId/delivered', {});
    if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    throw Exception(_api.parseError(r));
  }
}
