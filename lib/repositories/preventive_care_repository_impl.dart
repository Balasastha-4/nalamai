import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'interfaces/preventive_care_repository.dart';
import '../../core/api_client.dart';

class PreventiveCareRepositoryImpl implements IPreventiveCareRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Map<String, dynamic>> getPatientEligibility(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/eligibility/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to fetch eligibility'};
    } catch (e) {
      debugPrint('Error fetching eligibility: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> getPatientHRA(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/hra/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to fetch HRA'};
    } catch (e) {
      debugPrint('Error fetching HRA: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> submitHRA(Map<String, dynamic> hraData) async {
    try {
      final response = await _apiClient.post('/api/preventive/hra', body: hraData);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to submit HRA'};
    } catch (e) {
      debugPrint('Error submitting HRA: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<List<dynamic>> getPreventionPlans(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/plans/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      debugPrint('Error fetching plans: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getActivePlan(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/plans/$patientId/active');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'No active plan'};
    } catch (e) {
      debugPrint('Error fetching active plan: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<List<dynamic>> getFollowUps(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/followups/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      debugPrint('Error fetching follow-ups: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getAdherenceStats(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/followups/$patientId/adherence');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'adherenceScore': 0};
    } catch (e) {
      debugPrint('Error fetching adherence: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> predictNoShow(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/noshow/predict/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to predict'};
    } catch (e) {
      debugPrint('Error predicting no-show: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> assessRisk(String patientId) async {
    try {
      final response = await _apiClient.get('/api/preventive/risk/assess/$patientId');
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'error': 'Failed to assess risk'};
    } catch (e) {
      debugPrint('Error assessing risk: $e');
      return {'error': e.toString()};
    }
  }
}
