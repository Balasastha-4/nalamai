import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'interfaces/appointments_repository.dart';
import '../../models/schedule_model.dart';
import '../../core/api_client.dart';
import '../../services/auth_service.dart';

class AppointmentsRepositoryImpl implements IAppointmentsRepository {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  @override
  Future<List<ScheduleItem>> getAppointments(bool isDoctor) async {
    try {
      final userId = await _authService.getUserId();
      debugPrint('AppointmentsRepositoryImpl [getAppointments]: userId=$userId, isDoctor=$isDoctor');
      if (userId == null) return [];

      final endpoint = isDoctor ? '/api/appointments/doctor/$userId' : '/api/appointments/patient/$userId';
      final response = await _apiClient.get(endpoint);

      debugPrint('AppointmentsRepositoryImpl [getAppointments]: url=$endpoint, status=${response.statusCode}, body=${response.body}');

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

  @override
  Future<bool> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime appointmentTime,
    String? notes,
  }) async {
    try {
      final payload = {
        'patientId': int.tryParse(patientId) ?? int.tryParse(await _authService.getUserId() ?? '1') ?? 1,
        'doctorId': int.tryParse(doctorId) ?? 1,
        'appointmentTime': appointmentTime.toIso8601String(),
        'notes': notes ?? 'Consultation',
      };
      debugPrint('AppointmentsRepositoryImpl [createAppointment]: payload=$payload');

      final response = await _apiClient.post('/api/appointments', body: payload);
      debugPrint('AppointmentsRepositoryImpl [createAppointment]: status=${response.statusCode}, body=${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      return false;
    }
  }
}
