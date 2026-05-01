import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import '../services/auth_service.dart';

class ApiClient {
  static String _backendUrl = AppConfig.backendBaseUrl;
  static String _aiServiceUrl = AppConfig.aiServiceBaseUrl;

  static String get baseUrl => _backendUrl;
  static String get aiBaseUrl => _aiServiceUrl;

  final AuthService _authService = AuthService();
  final http.Client _client = http.Client();

  // Configure custom backend URL
  static void configureBackendUrl(String url) {
    _backendUrl = url;
    debugPrint('Backend URL configured: $url');
  }

  // Configure custom AI service URL
  static void configureAiServiceUrl(String url) {
    _aiServiceUrl = url;
    debugPrint('AI Service URL configured: $url');
  }

  // Configure both URLs at once
  static void configureUrls({String? backendUrl, String? aiServiceUrl}) {
    if (backendUrl != null) _backendUrl = backendUrl;
    if (aiServiceUrl != null) _aiServiceUrl = aiServiceUrl;
    debugPrint('URLs configured - Backend: $_backendUrl, AI: $_aiServiceUrl');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint, {bool isAiService = false}) async {
    final base = isAiService ? _aiServiceUrl : _backendUrl;
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();
    return await _client.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, {dynamic body, bool isAiService = false}) async {
    final base = isAiService ? _aiServiceUrl : _backendUrl;
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();
    return await _client.post(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, {dynamic body, bool isAiService = false}) async {
    final base = isAiService ? _aiServiceUrl : _backendUrl;
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();
    return await _client.put(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint, {bool isAiService = false}) async {
    final base = isAiService ? _aiServiceUrl : _backendUrl;
    final url = Uri.parse('$base$endpoint');
    final headers = await _getHeaders();
    return await _client.delete(url, headers: headers);
  }
}
