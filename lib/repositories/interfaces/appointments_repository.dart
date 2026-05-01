import '../../models/schedule_model.dart';

abstract class IAppointmentsRepository {
  Future<List<ScheduleItem>> getAppointments(bool isDoctor);
  Future<bool> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime appointmentTime,
    String? notes,
  });
}
