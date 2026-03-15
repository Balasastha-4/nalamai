import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/animations/animated_login_header.dart';
import '../widgets/animations/custom_route_transition.dart';
import '../widgets/animations/fade_in_slide.dart';
import 'main_screen.dart';
import 'doctor_main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDoctor;

  const RegisterScreen({super.key, required this.isDoctor});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final role = widget.isDoctor ? 'doctor' : 'patient';
      
      await authService.registerUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      // Successfully registered, now log them in
      await authService.login(email, password);

      if (!mounted) return;

      final Widget destination = widget.isDoctor
          ? const DoctorMainScreen()
          : const MainScreen();

      Navigator.pushAndRemoveUntil(
        context,
        CustomRouteTransition(page: destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: ${e.toString().replaceAll("Exception:", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = widget.isDoctor ? 'Doctor' : 'Patient';
    final themeColor = widget.isDoctor
        ? AppTheme.secondaryTeal
        : AppTheme.primaryBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Top Animated Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: AnimatedLoginHeader(primaryColor: themeColor),
          ),

          // Custom Back Button over animation
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bottom Form Area
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 40.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInSlide(
                      child: Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Join as a $roleTitle',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 200),
                      child: TextField(
                        controller: _nameController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          filled: false,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 300),
                      child: TextField(
                        controller: _emailController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          filled: false,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 400),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          suffixIcon: Icon(
                            Icons.visibility_outlined,
                            color: Colors.grey.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          filled: false,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 500),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 600),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            CustomRouteTransition(
                              page: LoginScreen(isDoctor: widget.isDoctor),
                            ),
                          );
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
