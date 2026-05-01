import 'package:flutter/material.dart';

import 'package:nalamai/screens/pin_screen.dart';
import 'package:nalamai/services/auth_service.dart';
import 'package:nalamai/theme/app_theme.dart';
import '../widgets/animations/custom_route_transition.dart';
import 'package:nalamai/screens/role_selection_screen.dart';
import 'package:nalamai/services/theme_service.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isAuthEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    final enabled = await _authService.isAuthEnabled();
    if (mounted) {
      setState(() {
        _isAuthEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          _buildSettingsTile(
            context,
            icon: Icons.brightness_6_outlined,
            title: 'App Theme',
            subtitle: _getThemeText(Theme.of(context).brightness),
            onTap: () => _showThemeDialog(context),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Security'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryBlue,
                ),
              ),
              title: Text(
                'App Lock',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Secure app with PIN',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _isAuthEnabled,
              activeTrackColor: AppTheme.primaryBlue.withAlpha(100),
              onChanged: (value) async {
                if (value) {
                  // Enable
                  final success = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PinScreen(isSetup: true),
                    ),
                  );
                  if (!mounted) return;
                  if (success == true) {
                    setState(() {
                      _isAuthEnabled = true;
                    });
                  }
                } else {
                  // Disable
                  await _authService.setAuthEnabled(false);
                  setState(() {
                    _isAuthEnabled = false;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.build_circle_outlined,
            title: 'Diagnostics',
            subtitle: 'Test Telemedicine & ML Service',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DiagnosticsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            iconColor: Colors.red,
            iconBgColor: Colors.red.withAlpha(26),
            titleColor: Colors.red,
            onTap: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                CustomRouteTransition(page: const RoleSelectionScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? iconBgColor,
    Color? titleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor ?? AppTheme.primaryBlue.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primaryBlue),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).iconTheme.color?.withAlpha(100),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  String _getThemeText(Brightness brightness) {
    final mode = ThemeService().themeMode;
    if (mode == ThemeMode.system) return 'System Default';
    if (mode == ThemeMode.light) return 'Light Mode';
    return 'Dark Mode';
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final themeService = ThemeService();
        return SimpleDialog(
          title: const Text('Select Theme'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                themeService.updateThemeMode(ThemeMode.system);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('System Default'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                themeService.updateThemeMode(ThemeMode.light);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Light Mode'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                themeService.updateThemeMode(ThemeMode.dark);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Dark Mode'),
              ),
            ),
          ],
        );
      },
    );
  }
}
