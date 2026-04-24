import 'package:flutter/foundation.dart' show kIsWeb;

/// Central API hosts for this machine on your LAN ([_lanHost]).
///
/// Android emulator → host: `flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8080`
abstract final class AppConfig {
  static const String _lanHost = '10.166.144.214';

  static const String _backendFromDefine = String.fromEnvironment(
    'BACKEND_BASE_URL',
  );
  static const String _aiFromDefine = String.fromEnvironment(
    'AI_BASE_URL',
  );

  /// Spring Boot (JWT, appointments, …)
  static String get backendBaseUrl {
    if (_backendFromDefine.isNotEmpty) return _backendFromDefine;
    if (kIsWeb) return 'http://localhost:8080';
    return 'http://$_lanHost:8080';
  }

  /// Python AI service
  static String get aiServiceBaseUrl {
    if (_aiFromDefine.isNotEmpty) return _aiFromDefine;
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://$_lanHost:8000';
  }
}
