import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import '../models/medical_record.dart';
import '../models/schedule_model.dart';
import 'auth_service.dart';

class ApiService {
  static String _backendUrl = AppConfig.backendBaseUrl;
  static String _aiServiceUrl = AppConfig.aiServiceBaseUrl;

  static String get baseUrl => _backendUrl;
  static String get aiBaseUrl => _aiServiceUrl;

  final AuthService _authService = AuthService();

  // Configure custom backend URL
  static void configureBackendUrl(String url) {
    _backendUrl = url;
    debugPrint('Backend URL configured: $url');
  }

  // Configure custom AI service URL
  static void configureAiServiceUrl(String url) {
    _aiServiceUrl = url;
    debugPrint('AI Service URL configured: $url');
  }

  // Configure both URLs at once
  static void configureUrls({String? backendUrl, String? aiServiceUrl}) {
    if (backendUrl != null) _backendUrl = backendUrl;
    if (aiServiceUrl != null) _aiServiceUrl = aiServiceUrl;
    debugPrint('URLs configured - Backend: $_backendUrl, AI: $_aiServiceUrl');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ScheduleItem>> getAppointments(bool isDoctor) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      final endpoint = isDoctor ? 'doctor' : 'patient';
      final response = await http.get(
        Uri.parse('$baseUrl/api/appointments/$endpoint/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ScheduleItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  Future<List<MedicalRecord>> getMedicalRecords() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/api/records/patient/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MedicalRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching medical records: $e');
      return [];
    }
  }

  Future<bool> saveMedicalRecord({
    required String patientId,
    required String diagnosis,
    List<String> medicines = const [],
    String notes = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/records/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'diagnosis': diagnosis,
          'prescription': medicines.join(', '),
          'notes': notes,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving record to DB: $e');
      return false;
    }
  }

  // ============ PREVENTIVE CARE API ENDPOINTS ============

  Future<Map<String, dynamic>> getPatientEligibility(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/eligibility/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch eligibility'};
    } catch (e) {
      debugPrint('Error fetching eligibility: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPatientHRA(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/hra/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch HRA'};
    } catch (e) {
      debugPrint('Error fetching HRA: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitHRA(Map<String, dynamic> hraData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/preventive/hra'),
        headers: await _getHeaders(),
        body: jsonEncode(hraData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to submit HRA'};
    } catch (e) {
      debugPrint('Error submitting HRA: $e');
      return {'error': e.toString()};
    }
  }

  Future<List<dynamic>> getPreventionPlans(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/plans/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching plans: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getActivePlan(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/plans/$patientId/active'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'No active plan'};
    } catch (e) {
      debugPrint('Error fetching active plan: $e');
      return {'error': e.toString()};
    }
  }

  Future<List<dynamic>> getFollowUps(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/followups/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching follow-ups: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAdherenceStats(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/followups/$patientId/adherence'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'adherenceScore': 0};
    } catch (e) {
      debugPrint('Error fetching adherence: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> predictNoShow(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/noshow/predict/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to predict'};
    } catch (e) {
      debugPrint('Error predicting no-show: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> assessRisk(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/risk/assess/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to assess risk'};
    } catch (e) {
      debugPrint('Error assessing risk: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPatientAnalytics(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/analytics/patient/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to get analytics'};
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOverviewAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/preventive/analytics/overview'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to get overview'};
    } catch (e) {
      debugPrint('Error fetching overview: $e');
      return {'error': e.toString()};
    }
  }
}
