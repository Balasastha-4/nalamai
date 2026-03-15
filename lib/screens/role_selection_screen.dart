import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations/fade_in_slide.dart';
import '../widgets/animations/ambient_glow_background.dart';
import '../widgets/animations/custom_route_transition.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _handleRoleSelection(BuildContext context, bool isDoctor) {
    Navigator.push(
      context,
      CustomRouteTransition(page: LoginScreen(isDoctor: isDoctor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by AmbientGlow
      body: AmbientGlowBackground(
        primaryGlowColor: AppTheme.primaryBlue,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              FadeInSlide(
                child: Text(
                  'Welcome to\nSmart Healthcare',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Please select your role to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ),
              const Spacer(),
              FadeInSlide(
                delay: const Duration(milliseconds: 400),
                child: _buildRoleCard(
                  context,
                  title: 'Patient',
                  description: 'Manage your health records & appointments',
                  icon: Icons.person_outline,
                  color: AppTheme.primaryBlue,
                  onTap: () => _handleRoleSelection(context, false),
                ),
              ),
              const SizedBox(height: 20),
              FadeInSlide(
                delay: const Duration(milliseconds: 600),
                child: _buildRoleCard(
                  context,
                  title: 'Doctor',
                  description: 'View patients & manage schedule',
                  icon: Icons.medical_services_outlined,
                  color: AppTheme.secondaryTeal,
                  onTap: () => _handleRoleSelection(context, true),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Hero(
                  tag: 'role_icon_$title',
                  child: Icon(icon, color: color, size: 32),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
