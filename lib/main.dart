import 'package:flutter/material.dart';
import 'package:nalamai/screens/splash_screen.dart';
import 'package:nalamai/theme/app_theme.dart';
import 'package:nalamai/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = ThemeService();
  await themeService.loadTheme();
  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'NalamAI',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
