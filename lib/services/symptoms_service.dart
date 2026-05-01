import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/api_client.dart';

/// Symptom model for symptom checker
class Symptom {
  final String name;
  final String severity; // mild, moderate, severe
  final String? duration;
  final String? notes;

  Symptom({
    required this.name,
    this.severity = 'moderate',
    this.duration,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'severity': severity,
    'duration': duration,
    'notes': notes,
  };
}

/// Service for AI-powered symptom checking
class SymptomsService {
  static String get _baseUrl => '${ApiClient.aiBaseUrl}/api/ai';
  final AuthService _authService = AuthService();

  /// Check symptoms with AI analysis
  Future<Map<String, dynamic>> checkSymptoms({
    required List<Symptom> symptoms,
    int? age,
    String? gender,
    List<String>? medicalHistory,
    List<String>? currentMedications,
  }) async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      final response = await http.post(
        Uri.parse('$_baseUrl/symptoms/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': userId,
          'symptoms': symptoms.map((s) => s.toJson()).toList(),
          'age': age,
          'gender': gender,
          'medical_history': medicalHistory,
          'current_medications': currentMedications,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to check symptoms: ${response.statusCode}');
    } catch (e) {
      debugPrint('SymptomsService Error: $e');
      throw Exception('Network error checking symptoms.');
    }
  }

  /// Quick single symptom check
  Future<Map<String, dynamic>> quickCheck(String symptom) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/symptoms/quick-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symptom': symptom}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to quick check: ${response.statusCode}');
    } catch (e) {
      debugPrint('SymptomsService Error: $e');
      throw Exception('Network error with quick check.');
    }
  }

  /// Get list of common symptoms for selection
  Future<Map<String, List<String>>> getCommonSymptoms() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/symptoms/common'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = data['categories'] as Map<String, dynamic>;
        return categories.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        );
      }
      throw Exception('Failed to fetch symptoms list: ${response.statusCode}');
    } catch (e) {
      debugPrint('SymptomsService Error: $e');
      // Return default list
      return {
        'General': ['Fever', 'Fatigue', 'Weakness'],
        'Head & Neck': ['Headache', 'Dizziness', 'Sore throat'],
        'Respiratory': ['Cough', 'Shortness of breath', 'Chest pain'],
        'Digestive': ['Nausea', 'Vomiting', 'Abdominal pain'],
        'Musculoskeletal': ['Back pain', 'Joint pain', 'Muscle aches'],
      };
    }
  }

  /// Check for emergency symptoms
  Future<Map<String, dynamic>> emergencyCheck(List<String> symptoms) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/symptoms/emergency-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(symptoms),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to emergency check: ${response.statusCode}');
    } catch (e) {
      debugPrint('SymptomsService Error: $e');
      throw Exception('Network error with emergency check.');
    }
  }
}
