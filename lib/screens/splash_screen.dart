import 'package:flutter/material.dart';
import 'package:nalamai/services/auth_service.dart';
import 'package:nalamai/utils/app_lock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nalamai/screens/main_screen.dart';
import 'package:nalamai/screens/doctor_main_screen.dart';
import 'package:nalamai/screens/role_selection_screen.dart';
import 'package:nalamai/theme/app_theme.dart';
import 'package:nalamai/widgets/animations/animated_splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Longer artificial delay to allow the full vector animation to play out and impress the user
    await Future.delayed(const Duration(milliseconds: 3000));

    final prefs = await SharedPreferences.getInstance();
    final isAppLockEnabled = prefs.getBool('is_app_lock_enabled') ?? false;

    if (isAppLockEnabled) {
      final appLockService = AppLockService();
      final isAuthenticated = await appLockService.authenticate();

      if (!isAuthenticated) {
        if (mounted) {
          setState(() {
            _isLocked = true;
          });
        }
        return;
      }
    }

    if (!mounted) return;

    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final role = await authService.getUserRole();
      if (!mounted) return;

      if (role == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorMainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedSplashLogo(size: 140, color: Colors.white),
            const SizedBox(height: 32),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeIn,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: const Text(
                'NALAMAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
              builder: (context, value, child) {
                return Opacity(opacity: value, child: child);
              },
              child: const Text(
                'Smart Healthcare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
      bottomNavigationBar: _isLocked
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _checkSession,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          : null,
    );
  }
}
