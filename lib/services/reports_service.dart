import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import 'package:flutter/foundation.dart';

class ReportsService {
  static const String _storageKey = 'saved_reports';

  // Save a single report to the list
  Future<void> saveReport(Report report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> reportsJson = prefs.getStringList(_storageKey) ?? [];

      // Add new report to the list (serializing to JSON string)
      reportsJson.add(jsonEncode(report.toJson()));

      await prefs.setStringList(_storageKey, reportsJson);
      debugPrint('Report saved: ${report.id}');
    } catch (e) {
      debugPrint('Error saving report: $e');
      rethrow;
    }
  }

  // Retrieve all saved reports
  Future<List<Report>> getReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> reportsJson = prefs.getStringList(_storageKey) ?? [];

      return reportsJson
          .map((reportString) => Report.fromJson(jsonDecode(reportString)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  // Clear all reports (optional utility)
  Future<void> clearReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
