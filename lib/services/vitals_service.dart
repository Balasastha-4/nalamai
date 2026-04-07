import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

/// Service for managing vitals data
class VitalsService {
  // Use configurable URLs from ApiService
  static String get _baseUrl => '${ApiService.aiBaseUrl}/api/ai';
  static String get _javaUrl => '${ApiService.baseUrl}/api';
  final AuthService _authService = AuthService();

  /// Get latest vitals for a patient
  Future<Map<String, dynamic>> getLatestVitals() async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final response = await http.get(
        Uri.parse('$_baseUrl/vitals/latest/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch vitals: ${response.statusCode}');
    } catch (e) {
      debugPrint('VitalsService Error: $e');
      // Return demo data on error
      return _getDemoVitals();
    }
  }

  /// Record new vital readings
  Future<Map<String, dynamic>> recordVitals(
    List<Map<String, dynamic>> vitals,
  ) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/vitals/record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': userId,
          'vitals': vitals,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to record vitals: ${response.statusCode}');
    } catch (e) {
      debugPrint('VitalsService Error: $e');
      throw Exception('Network error recording vitals.');
    }
  }

  /// Analyze vitals with AI insights
  Future<Map<String, dynamic>> analyzeVitals({int days = 7}) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/vitals/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_id': userId, 'days': days, 'token': token}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to analyze vitals: ${response.statusCode}');
    } catch (e) {
      debugPrint('VitalsService Error: $e');
      throw Exception('Network error analyzing vitals.');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _getDemoVitals() {
    return {
      'status': 'success',
      'vitals': {
        'HeartRate': {'value': 75, 'unit': 'bpm', 'status': 'normal'},
        'BP_Systolic': {'value': 120, 'unit': 'mmHg', 'status': 'normal'},
        'BP_Diastolic': {'value': 80, 'unit': 'mmHg', 'status': 'normal'},
        'SpO2': {'value': 98, 'unit': '%', 'status': 'normal'},
        'Temperature': {'value': 36.6, 'unit': '°C', 'status': 'normal'},
      },
      'source': 'demo',
    };
  }
}
