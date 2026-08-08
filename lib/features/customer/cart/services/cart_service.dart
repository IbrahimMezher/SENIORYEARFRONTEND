import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class CartService {
  final _api = ApiService();

  Future<List<dynamic>> getCart() async {
    final r = await _api.get('/cart');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load cart');
  }

  Future<String> removeFromCart(int cartItemId) async {
    final r = await _api.delete('/cart/$cartItemId');
    if (r.statusCode == 200) return r.body;
    throw Exception('Failed to remove item');
  }

  Future<String> clearCart() async {
    final r = await _api.delete('/cart/clear');
    if (r.statusCode == 200) return r.body;
    throw Exception('Failed to clear cart');
  }
}
