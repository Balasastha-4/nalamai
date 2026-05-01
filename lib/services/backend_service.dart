import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/medical_record.dart';
import 'interfaces/backend_service_interface.dart';
import 'auth_service.dart';
import '../core/api_client.dart';

class RESTBackendService implements BackendService {
  static String get _javaBaseUrl => '${ApiClient.baseUrl}/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<void> syncUserData(UserProfile profile) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final response = await http.put(
        Uri.parse('$_javaBaseUrl/users/$userId/profile'),
        headers: await _getHeaders(),
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to sync user data: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to sync user data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('RESTBackendService syncUserData error: $e');
      rethrow;
    }
  }

  @override
  Future<UserProfile?> fetchUserData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_javaBaseUrl/users/$userId/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('RESTBackendService fetchUserData error: $e');
      return null;
    }
  }

  // The MedicalRecords methods proxy to existing implementations or make direct calls
  @override
  Future<List<MedicalRecord>> fetchMedicalRecords(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_javaBaseUrl/patients/$userId/records'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => MedicalRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('RESTBackendService fetchMedicalRecords error: $e');
      return [];
    }
  }

  @override
  Future<void> saveMedicalRecord(MedicalRecord record) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final recordJson = record.toJson();
      recordJson['patientId'] = int.tryParse(userId) ?? 1;

      final response = await http.post(
        Uri.parse('$_javaBaseUrl/records'),
        headers: await _getHeaders(),
        body: jsonEncode(recordJson),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save medical record');
      }
    } catch (e) {
      debugPrint('RESTBackendService saveMedicalRecord error: $e');
      rethrow;
    }
  }
}

class BackendServiceProvider {
  static BackendService _instance = RESTBackendService();

  static BackendService get instance => _instance;

  static void inject(BackendService service) {
    _instance = service;
  }
}
