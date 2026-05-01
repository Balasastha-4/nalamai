import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/api_client.dart';

/// Alert model for notifications
class HealthAlert {
  final String id;
  final String type;
  final String severity; // low, medium, high, critical
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  HealthAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) => HealthAlert(
    id: json['id']?.toString() ?? '',
    type: json['type'] ?? 'general',
    severity: json['severity'] ?? 'low',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'])
        : DateTime.now(),
    isRead: json['isRead'] ?? json['read'] ?? false,
    data: json['data'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'severity': severity,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };
}

/// Service for health alerts and notifications
class AlertsService {
  // Use configurable URL from ApiClient
  static String get _baseUrl => '${ApiClient.baseUrl}/api';
  final AuthService _authService = AuthService();

  /// Get all alerts for current user
  Future<List<HealthAlert>> getAlerts({
    String? severity,
    bool? unreadOnly,
    int limit = 50,
  }) async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      var url = '$_baseUrl/alerts/patient/$userId?limit=$limit';
      if (severity != null) url += '&severity=$severity';
      if (unreadOnly == true) url += '&unread=true';

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List alerts = data is List ? data : (data['alerts'] ?? []);
        return alerts.map((a) => HealthAlert.fromJson(a)).toList();
      }
      throw Exception('Failed to fetch alerts: ${response.statusCode}');
    } catch (e) {
      debugPrint('AlertsService Error: $e');
      return _getDemoAlerts();
    }
  }

  /// Get unread alert count
  Future<int> getUnreadCount() async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      final response = await http.get(
        Uri.parse('$_baseUrl/alerts/patient/$userId/unread-count'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('AlertsService Error: $e');
      return 0;
    }
  }

  /// Mark alert as read
  Future<bool> markAsRead(String alertId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/alerts/$alertId/read'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AlertsService Error: $e');
      return false;
    }
  }

  /// Mark all alerts as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      final response = await http.put(
        Uri.parse('$_baseUrl/alerts/patient/$userId/read-all'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AlertsService Error: $e');
      return false;
    }
  }

  /// Dismiss/resolve an alert
  Future<bool> dismissAlert(String alertId, {String? resolutionNote}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/alerts/$alertId/resolve'),
        headers: await _getHeaders(),
        body: jsonEncode({'resolution_note': resolutionNote}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('AlertsService Error: $e');
      return false;
    }
  }

  /// Create a new health alert (typically from vitals monitoring)
  Future<HealthAlert?> createAlert({
    required String type,
    required String severity,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      final response = await http.post(
        Uri.parse('$_baseUrl/alerts'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patientId': userId,
          'type': type,
          'severity': severity,
          'title': title,
          'message': message,
          'data': data,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return HealthAlert.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('AlertsService Error: $e');
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<HealthAlert> _getDemoAlerts() {
    final now = DateTime.now();
    return [
      HealthAlert(
        id: '1',
        type: 'vitals',
        severity: 'medium',
        title: 'Blood Pressure Alert',
        message: 'Your blood pressure reading (135/88) is slightly elevated.',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      HealthAlert(
        id: '2',
        type: 'appointment',
        severity: 'low',
        title: 'Appointment Reminder',
        message: 'You have an appointment tomorrow at 10:00 AM with Dr. Smith.',
        timestamp: now.subtract(const Duration(hours: 12)),
        isRead: true,
      ),
      HealthAlert(
        id: '3',
        type: 'medication',
        severity: 'low',
        title: 'Medication Reminder',
        message: 'Time to take your evening medication.',
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: false,
      ),
    ];
  }
}
