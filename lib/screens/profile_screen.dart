import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/animations/custom_route_transition.dart';
import '../widgets/feedback/success_feedback.dart';
import 'role_selection_screen.dart';

import '../utils/app_lock_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;

  bool _isLoading = true;
  bool _isAppLockEnabled = false;
  final _appLockService = AppLockService();

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _historyController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _historyController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileJson = prefs.getString('user_profile');
    final bool isAppLockEnabled = prefs.getBool('is_app_lock_enabled') ?? false;

    setState(() {
      if (profileJson != null) {
        _profile = UserProfile.fromJsonString(profileJson);
      } else {
        _profile = UserProfile.empty();
      }
      _isAppLockEnabled = isAppLockEnabled;
      _populateControllers();
      _isLoading = false;
    });
  }

  void _populateControllers() {
    _nameController.text = _profile.name;
    _ageController.text = _profile.age;
    _bloodGroupController.text = _profile.bloodGroup;
    _allergiesController.text = _profile.allergies;
    _historyController.text = _profile.medicalHistory;
    _emergencyNameController.text = _profile.emergencyContactName;
    _emergencyPhoneController.text = _profile.emergencyContactPhone;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _profile = UserProfile(
        name: _nameController.text,
        age: _ageController.text,
        bloodGroup: _bloodGroupController.text,
        allergies: _allergiesController.text,
        medicalHistory: _historyController.text,
        emergencyContactName: _emergencyNameController.text,
        emergencyContactPhone: _emergencyPhoneController.text,
      );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', _profile.toJsonString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showEditProfileModal(context),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            // Premium Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPremiumStatCard(
                      '${_ageController.text} Yrs',
                      'Age',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPremiumStatCard(
                      _bloodGroupController.text.isEmpty
                          ? '-'
                          : _bloodGroupController.text,
                      'Blood',
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPremiumStatCard(
                      '75 kg',
                      'Weight',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Content Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle(context, 'Medical Information'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          context,
                          'Allergies',
                          _allergiesController,
                          Icons.warning_amber_rounded,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          context,
                          'Medical History',
                          _historyController,
                          Icons.history,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle(context, 'Emergency Contact'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          context,
                          'Contact Name',
                          _emergencyNameController,
                          Icons.person_outline,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          context,
                          'Phone Number',
                          _emergencyPhoneController,
                          Icons.phone_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle(context, 'Settings'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          Icons.notifications_outlined,
                          'Notifications',
                          () {},
                        ),
                        _buildDivider(),
                        _buildListTile(
                          context,
                          Icons.brightness_6_outlined,
                          'App Theme',
                          () => _showThemeDialog(context),
                        ),
                        _buildDivider(),
                        _buildListTile(
                          context,
                          Icons.lock_outline,
                          'App Lock',
                          () => _handleAppLockToggle(),
                          trailing: Switch(
                            value: _isAppLockEnabled,
                            onChanged: (value) => _handleAppLockToggle(),
                            activeTrackColor: AppTheme.primaryBlue,
                          ),
                        ),
                        _buildDivider(),
                        _buildListTile(
                          context,
                          Icons.security,
                          'Privacy & Security',
                          () {},
                        ),
                        _buildDivider(),
                        _buildListTile(
                          context,
                          Icons.help_outline,
                          'Help & Support',
                          () {},
                        ),
                        _buildDivider(),
                        _buildListTile(
                          context,
                          Icons.logout,
                          'Logout',
                          () async {
                            final authService = AuthService();
                            await authService.logout();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              CustomRouteTransition(
                                page: const RoleSelectionScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          textColor: AppTheme.error,
                          iconColor: AppTheme.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Clean Premium Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.secondaryTeal,
                child: Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Name Field
        Text(
          _profile.name.isEmpty ? 'Guest User' : _profile.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue, size: 22),
      title: Text(
        controller.text.isEmpty ? 'Not set' : controller.text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    );
  }

  void _showEditProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildEditTextField(
                  context,
                  'Full Name',
                  _nameController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEditTextField(
                        context,
                        'Age',
                        _ageController,
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildEditTextField(
                        context,
                        'Blood Group',
                        _bloodGroupController,
                        Icons.bloodtype_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Allergies',
                  _allergiesController,
                  Icons.warning_amber_rounded,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Medical History',
                  _historyController,
                  Icons.history,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Emergency Contact Name',
                  _emergencyNameController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Emergency Phone',
                  _emergencyPhoneController,
                  Icons.phone_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveProfile();
                      if (!context.mounted) return;
                      Navigator.pop(context);

                      // Show success feedback
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SuccessFeedback(
                              message: 'Profile Updated Successfully!',
                              onDismissed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
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

  Future<void> _handleAppLockToggle() async {
    // If enabling, authenticate first
    if (!_isAppLockEnabled) {
      final didAuthenticate = await _appLockService.authenticate();
      if (!didAuthenticate) return;
    }

    setState(() {
      _isAppLockEnabled = !_isAppLockEnabled;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_app_lock_enabled', _isAppLockEnabled);
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Color? textColor,
    Color? iconColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryBlue),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Theme.of(context).dividerColor)
              : null),
      onTap: onTap,
    );
  }
}
