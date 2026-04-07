import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';

/// Service for interacting with the enhanced AI Agent and Preventive Care Agentic AI
class AgentService {
  // Use configurable base URL from ApiService - AI service runs on port 8000
  static String get _baseUrl => '${ApiService.aiBaseUrl}/api/ai';
  static String get _preventiveUrl => '${ApiService.aiBaseUrl}/api/ai/preventive';
  final AuthService _authService = AuthService();

  /// Send a message to the AI agent with function calling capabilities
  Future<Map<String, dynamic>> chat({
    required String message,
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = await _authService.getUserId() ?? '1';
      final token = await _authService.getToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/agent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'user_id': userId,
          'conversation_history': conversationHistory ?? [],
          'context': context ?? {},
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Agent request failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('AgentService Error: $e');
      return {
        'status': 'error',
        'response': 'Sorry, I encountered an error. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get agent capabilities/available tools
  Future<Map<String, dynamic>> getCapabilities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/agent/capabilities'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get capabilities: ${response.statusCode}');
    } catch (e) {
      debugPrint('AgentService Error: $e');
      return {
        'capabilities': [
          'Check and analyze health vitals',
          'Manage appointments',
          'Review medical history',
          'Medication information',
          'Find doctors and specialists',
          'Symptom assessment',
          'Health analytics and trends',
        ],
      };
    }
  }

  /// Quick health query - simplified interface for common queries
  Future<String> quickHealthQuery(String query) async {
    try {
      final result = await chat(
        message: query,
        context: {'mode': 'quick_query'},
      );
      return result['response'] ?? 'Unable to process your query.';
    } catch (e) {
      return 'Sorry, I couldn\'t process your health query. Please try again.';
    }
  }

  /// Get health summary from AI agent
  Future<Map<String, dynamic>> getHealthSummary() async {
    try {
      final userId = await _authService.getUserId() ?? '1';

      final response = await http.get(
        Uri.parse('$_baseUrl/agent/health-summary/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      // Fallback to chat for summary
      return await chat(
        message:
            'Give me a summary of my current health status including any recent vitals, upcoming appointments, and health recommendations.',
      );
    } catch (e) {
      debugPrint('AgentService Error: $e');
      return {'status': 'error', 'response': 'Unable to fetch health summary.'};
    }
  }

  /// Ask for medication info
  Future<Map<String, dynamic>> getMedicationInfo(String medicationName) async {
    return await chat(
      message:
          'Tell me about the medication $medicationName - what is it used for, common side effects, and any important precautions.',
      context: {'intent': 'medication_info', 'medication': medicationName},
    );
  }

  /// Find doctors by specialty
  Future<Map<String, dynamic>> findDoctors(
    String specialty, {
    String? location,
  }) async {
    String query = 'Find me $specialty doctors';
    if (location != null) {
      query += ' near $location';
    }

    return await chat(
      message: query,
      context: {
        'intent': 'find_doctors',
        'specialty': specialty,
        'location': location,
      },
    );
  }

  /// Get appointment suggestions
  Future<Map<String, dynamic>> getAppointmentSuggestions() async {
    return await chat(
      message:
          'Based on my health data and history, what appointments or checkups should I schedule?',
      context: {'intent': 'appointment_suggestions'},
    );
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ PREVENTIVE CARE AGENTIC AI METHODS ============

  /// Execute the full preventive healthcare workflow for a patient
  Future<Map<String, dynamic>> executePreventiveWorkflow({
    required String patientId,
    String? targetStep,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/workflow/execute'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'target_step': targetStep,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Workflow execution failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('PreventiveWorkflow Error: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Get workflow status for a patient
  Future<Map<String, dynamic>> getWorkflowStatus(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/workflow/status/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get workflow status: ${response.statusCode}');
    } catch (e) {
      debugPrint('WorkflowStatus Error: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Check patient eligibility for preventive care programs
  Future<Map<String, dynamic>> checkEligibility(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/eligibility/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to check eligibility: ${response.statusCode}');
    } catch (e) {
      debugPrint('Eligibility Error: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Smart schedule an appointment using the scheduling agent
  Future<Map<String, dynamic>> smartSchedule({
    required String patientId,
    String? doctorId,
    String? preferredDate,
    String? preferredTime,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/scheduling/smart-schedule'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'doctor_id': doctorId,
          'preferred_date': preferredDate,
          'preferred_time': preferredTime,
          'reason': reason ?? 'Preventive care visit',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Smart scheduling failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('SmartSchedule Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get optimal appointment slots using AI
  Future<Map<String, dynamic>> getOptimalSlots({
    required String patientId,
    String? doctorId,
    String? preferredDate,
    int count = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/scheduling/optimal-slots'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'doctor_id': doctorId,
          'preferred_date': preferredDate,
          'count': count,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get optimal slots: ${response.statusCode}');
    } catch (e) {
      debugPrint('OptimalSlots Error: $e');
      return {'slots': []};
    }
  }

  /// Predict no-show probability for a patient
  Future<Map<String, dynamic>> predictNoShow(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/predict/no-show/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to predict no-show: ${response.statusCode}');
    } catch (e) {
      debugPrint('NoShowPrediction Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Assess health risk using the Predictive Agent
  Future<Map<String, dynamic>> assessHealthRisk(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/predict/health-risk/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to assess health risk: ${response.statusCode}');
    } catch (e) {
      debugPrint('HealthRisk Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Submit Health Risk Assessment (HRA)
  Future<Map<String, dynamic>> submitHRA({
    required String patientId,
    required Map<String, dynamic> hraData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/hra'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          ...hraData,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to submit HRA: ${response.statusCode}');
    } catch (e) {
      debugPrint('SubmitHRA Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get HRA status for a patient
  Future<Map<String, dynamic>> getHRAStatus(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/hra/$patientId/status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get HRA status: ${response.statusCode}');
    } catch (e) {
      debugPrint('HRAStatus Error: $e');
      return {'status': 'PENDING'};
    }
  }

  /// Generate a personalized prevention plan
  Future<Map<String, dynamic>> generatePreventionPlan(String patientId) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/prevention-plan/generate'),
        headers: await _getHeaders(),
        body: jsonEncode({'patient_id': patientId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to generate plan: ${response.statusCode}');
    } catch (e) {
      debugPrint('GeneratePlan Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Get active prevention plan
  Future<Map<String, dynamic>> getPreventionPlan(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/prevention-plan/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get plan: ${response.statusCode}');
    } catch (e) {
      debugPrint('GetPlan Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Get follow-ups for a patient
  Future<List<Map<String, dynamic>>> getFollowUps(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/follow-up/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return data['followups'] ?? [];
      }
      throw Exception('Failed to get follow-ups: ${response.statusCode}');
    } catch (e) {
      debugPrint('GetFollowUps Error: $e');
      return [];
    }
  }

  /// Submit feedback/response to a follow-up
  Future<Map<String, dynamic>> respondToFollowUp({
    required String followUpId,
    required String response,
    bool taskCompleted = false,
  }) async {
    try {
      final httpResponse = await http.post(
        Uri.parse('$_preventiveUrl/follow-up/$followUpId/respond'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'response': response,
          'task_completed': taskCompleted,
        }),
      );

      if (httpResponse.statusCode == 200) {
        return jsonDecode(httpResponse.body);
      }
      throw Exception('Failed to respond: ${httpResponse.statusCode}');
    } catch (e) {
      debugPrint('RespondFollowUp Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get adherence tracking data
  Future<Map<String, dynamic>> getAdherenceTracking(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/follow-up/$patientId/adherence'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get adherence: ${response.statusCode}');
    } catch (e) {
      debugPrint('Adherence Error: $e');
      return {'adherence_rate': 0};
    }
  }

  /// Get all active agents status
  Future<Map<String, dynamic>> getAgentsStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/agents'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get agents: ${response.statusCode}');
    } catch (e) {
      debugPrint('AgentsStatus Error: $e');
      return {'agents': {}};
    }
  }

  /// Chat with a specific agent
  Future<Map<String, dynamic>> chatWithAgent({
    required String agentType,
    required String message,
    String? patientId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = patientId ?? await _authService.getUserId() ?? '1';
      
      final response = await http.post(
        Uri.parse('$_preventiveUrl/agents/$agentType/chat'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'message': message,
          'patient_id': userId,
          'context': context ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Agent chat failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('AgentChat Error: $e');
      return {'status': 'error', 'response': e.toString()};
    }
  }

  /// Get patient analytics
  Future<Map<String, dynamic>> getPatientAnalytics(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/analytics/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get analytics: ${response.statusCode}');
    } catch (e) {
      debugPrint('Analytics Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Send notification through the notification agent
  Future<Map<String, dynamic>> sendNotification({
    required String patientId,
    required String type,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/notifications/send'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'notification_type': type,
          'message': message,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to send notification: ${response.statusCode}');
    } catch (e) {
      debugPrint('Notification Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get documentation summary for a visit
  Future<Map<String, dynamic>> getDocumentationSummary({
    required String patientId,
    String? visitId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_preventiveUrl/documentation/$patientId${visitId != null ? '/$visitId' : ''}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get documentation: ${response.statusCode}');
    } catch (e) {
      debugPrint('Documentation Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Generate clinical notes using AI
  Future<Map<String, dynamic>> generateClinicalNotes({
    required String patientId,
    required String visitType,
    Map<String, dynamic>? visitData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/documentation/generate'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'visit_type': visitType,
          'visit_data': visitData ?? {},
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to generate notes: ${response.statusCode}');
    } catch (e) {
      debugPrint('GenerateNotes Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Pre-fill billing claim
  Future<Map<String, dynamic>> prefillBillingClaim({
    required String patientId,
    required String visitId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_preventiveUrl/billing/prefill'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'patient_id': patientId,
          'visit_id': visitId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to prefill billing: ${response.statusCode}');
    } catch (e) {
      debugPrint('Billing Error: $e');
      return {'error': e.toString()};
    }
  }
}
