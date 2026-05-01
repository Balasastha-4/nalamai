abstract class IAnalyticsRepository {
  Future<Map<String, dynamic>> getPatientAnalytics(String patientId);
  Future<Map<String, dynamic>> getOverviewAnalytics();
}
