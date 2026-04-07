import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

/// Service for health analytics data and charts
class AnalyticsService {
  // Use configurable URL from ApiService
  static String get _baseUrl => '${ApiService.aiBaseUrl}/api/ai';
  final AuthService _authService = AuthService();

  /// Get analytics dashboard data for charts
  Future<Map<String, dynamic>> getDashboardData({
    String period = 'week',
    String? metricType,
  }) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/analytics/dashboard'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': userId,
          'period': period,
          'metric_type': metricType,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch analytics: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnalyticsService Error: $e');
      return _getDemoAnalytics(period);
    }
  }

  /// Get comprehensive health score
  Future<Map<String, dynamic>> getHealthScore() async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/analytics/health-score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': userId,
          'include_history': true,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch health score: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnalyticsService Error: $e');
      return {
        'status': 'success',
        'overall_score': 85,
        'category_scores': {
          'Cardiovascular': 90,
          'Respiratory': 88,
          'Metabolic': 82,
        },
        'ai_analysis':
            'Your overall health is good. Keep up with regular monitoring.',
        'improvement_tips': [
          'Exercise regularly',
          'Maintain a balanced diet',
          'Get adequate sleep',
        ],
      };
    }
  }

  /// Get health trends for specific metrics
  Future<Map<String, dynamic>> getHealthTrends({
    String metric = 'all',
    String period = 'week',
  }) async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/analytics/trends/$userId?metric=$metric&period=$period',
        ),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch trends: ${response.statusCode}');
    } catch (e) {
      debugPrint('AnalyticsService Error: $e');
      throw Exception('Network error fetching trends.');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _getDemoAnalytics(String period) {
    final days = period == 'day'
        ? ['Mon']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return {
      'status': 'success',
      'period': period,
      'health_score': 85,
      'ai_summary': 'Your vitals are stable. Continue monitoring regularly.',
      'alerts': [],
      'metrics': [
        {
          'metric': 'HeartRate',
          'data': days
              .map((d) => {'label': d, 'value': 72 + (days.indexOf(d) % 5)})
              .toList(),
          'average': 75.0,
          'min_val': 70,
          'max_val': 82,
          'trend_direction': 'stable',
          'percent_change': 1.2,
        },
        {
          'metric': 'BP_Systolic',
          'data': days
              .map((d) => {'label': d, 'value': 118 + (days.indexOf(d) % 8)})
              .toList(),
          'average': 122.0,
          'min_val': 118,
          'max_val': 128,
          'trend_direction': 'stable',
          'percent_change': 2.1,
        },
        {
          'metric': 'SpO2',
          'data': days
              .map((d) => {'label': d, 'value': 97 + (days.indexOf(d) % 2)})
              .toList(),
          'average': 98.0,
          'min_val': 97,
          'max_val': 99,
          'trend_direction': 'stable',
          'percent_change': 0.5,
        },
      ],
    };
  }
}
