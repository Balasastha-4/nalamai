import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/medical_record.dart';
import '../models/schedule_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://10.203.244.19:8080/api';
  final AuthService _authService = AuthService();

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
        Uri.parse('$_baseUrl/appointments/$endpoint/$userId'),
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
        Uri.parse('$_baseUrl/records/patient/$userId'),
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
        Uri.parse('$_baseUrl/records/'),
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
}
