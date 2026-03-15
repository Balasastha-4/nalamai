import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SuccessFeedback extends StatefulWidget {
  final String message;
  final VoidCallback? onDismissed;

  const SuccessFeedback({super.key, required this.message, this.onDismissed});

  @override
  State<SuccessFeedback> createState() => _SuccessFeedbackState();
}

class _SuccessFeedbackState extends State<SuccessFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _opacityAnimation,
            child: Text(
              widget.message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
