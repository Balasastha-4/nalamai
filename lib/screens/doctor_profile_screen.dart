import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/custom_route_transition.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/feedback/success_feedback.dart';
import 'role_selection_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String _name = 'Dr. Smith';
  String _title = 'Senior Cardiologist';
  String _phone = '+1 (555) 123-4567';
  String _email = 'dr.smith@hospital.com';
  String _location = 'City General Hospital, NY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showEditProfileModal(context),
            tooltip: 'Edit Profile (Demo)',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Clean Premium Header (No Gradient Banner)
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
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.secondaryTeal,
                child: Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Name & Title
            Text(
              _name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Premium Stats Row (Flexible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPremiumStatCard(
                      context,
                      '12 Yrs',
                      'Experience',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPremiumStatCard(
                      context,
                      '1.2k+',
                      'Patients',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPremiumStatCard(
                      context,
                      '4.8',
                      'Rating',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle(context, 'Contact Information'),
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
                        _buildListTile(context, Icons.phone, _phone, null),
                        _buildDivider(context),
                        _buildListTile(context, Icons.email, _email, null),
                        _buildDivider(context),
                        _buildListTile(
                          context,
                          Icons.location_on,
                          _location,
                          null,
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
                        _buildDivider(context),
                        _buildListTile(
                          context,
                          Icons.brightness_6_outlined,
                          'App Theme',
                          () => _showThemeDialog(context),
                        ),
                        _buildDivider(context),
                        _buildListTile(
                          context,
                          Icons.lock_outline,
                          'Privacy & Security',
                          () {},
                        ),
                        _buildDivider(context),
                        _buildListTile(
                          context,
                          Icons.help_outline,
                          'Help & Support',
                          () {},
                        ),
                        _buildDivider(context),
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

  Widget _buildPremiumStatCard(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Color? textColor,
    Color? iconColor,
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
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: Theme.of(context).dividerColor)
          : null,
      onTap: onTap,
    );
  }

  void _showEditProfileModal(BuildContext context) {
    final nameController = TextEditingController(text: _name);
    final titleController = TextEditingController(text: _title);
    final phoneController = TextEditingController(text: _phone);
    final emailController = TextEditingController(text: _email);
    final locationController = TextEditingController(text: _location);

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
                  nameController,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Title/Specialty',
                  titleController,
                  Icons.work_outline,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Phone Number',
                  phoneController,
                  Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Email',
                  emailController,
                  Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildEditTextField(
                  context,
                  'Location',
                  locationController,
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _name = nameController.text;
                        _title = titleController.text;
                        _phone = phoneController.text;
                        _email = emailController.text;
                        _location = locationController.text;
                      });
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
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
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
}
