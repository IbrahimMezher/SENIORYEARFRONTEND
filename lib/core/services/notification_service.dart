import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class NotificationService {
  final _api = ApiService();

  Future<List<dynamic>> getNotifications() async {
    final r = await _api.get('/notifications');
    if (r.statusCode == 200) return jsonDecode(utf8.decode(r.bodyBytes));
    throw Exception(_api.parseError(r));
  }

  Future<int> getUnreadCount() async {
    final r = await _api.get('/notifications/unread-count');
    if (r.statusCode == 200) {
      final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return body['count'] is int
          ? body['count'] as int
          : int.tryParse(body['count']?.toString() ?? '0') ?? 0;
    }
    throw Exception(_api.parseError(r));
  }

  Future<void> markRead(int notificationId) async {
    final r = await _api.put('/notifications/$notificationId/read', {});
    _api.ensureSuccess(r);
  }

  Future<void> markAllRead() async {
    final r = await _api.put('/notifications/read-all', {});
    _api.ensureSuccess(r);
  }
}
