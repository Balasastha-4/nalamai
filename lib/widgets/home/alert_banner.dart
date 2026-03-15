import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AlertBanner extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF4C1F1F), // Dark Red for visible alert
                  const Color(0xFF4C1F1F),
                ]
              : [const Color(0xFFFFF4F4), const Color(0xFFFFEBEE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.error.withValues(alpha: 0.5)
              : Colors.red.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.red[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(150),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.redAccent,
                ),
                onPressed: onTap,
              ),
            ),
        ],
      ),
    );
  }
}
