import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AppLockService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
