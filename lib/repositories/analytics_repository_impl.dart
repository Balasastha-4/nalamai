import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'interfaces/analytics_repository.dart';
import '../../core/api_client.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Map<String, dynamic>> getPatientAnalytics(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/analytics/patient/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to get analytics'};
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> getOverviewAnalytics() async {
    try {
      final response = await _apiClient.get('/api/preventive/analytics/overview');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to get overview'};
    } catch (e) {
      debugPrint('Error fetching overview: $e');
      return {'error': e.toString()};
    }
  }
}
