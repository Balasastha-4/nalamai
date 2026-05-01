import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'interfaces/medical_records_repository.dart';
import '../../models/medical_record.dart';
import '../../core/api_client.dart';
import '../../services/auth_service.dart';

class MedicalRecordsRepositoryImpl implements IMedicalRecordsRepository {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  @override
  Future<List<MedicalRecord>> getMedicalRecords() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      final response = await _apiClient.get('/api/records/patient/$userId');

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

  @override
  Future<bool> saveMedicalRecord({
    required String patientId,
    required String diagnosis,
    List<String> medicines = const [],
    String notes = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/records',
        body: {
          'patientId': int.tryParse(patientId) ?? 1,
          'diagnosis': diagnosis,
          'prescription': medicines.join(', '),
          'notes': notes,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving record to DB: $e');
      return false;
    }
  }
}
