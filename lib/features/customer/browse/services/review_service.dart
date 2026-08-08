import 'dart:convert';
import 'package:fluttertest/core/services/api_service.dart';

class ReviewService {
  final _api = ApiService();

  Future<List<dynamic>> getPolicyReviews(int policyId) async {
    final r = await _api.get('/reviews/policies/$policyId');
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Failed to load reviews');
  }

  Future<String> submitReview({
    required int policyId,
    required int rating,
    required String reviewText,
  }) async {
    final r = await _api.post('/reviews/create', {
      'policyId': policyId,
      'rating': rating,
      'reviewText': reviewText,
    });
    if (r.statusCode == 200) return r.body;
    throw Exception(_api.parseError(r));
  }
}
