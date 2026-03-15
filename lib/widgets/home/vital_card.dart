import 'package:flutter/material.dart';
import '../../models/vital.dart';
import '../../theme/app_theme.dart';

class VitalCard extends StatelessWidget {
  final Vital vital;

  const VitalCard({super.key, required this.vital});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, // Fixed width for horizontal scrolling
      margin: const EdgeInsets.only(
        bottom: 10,
        right: 16,
      ), // Shadow spacing and right margin
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vital.isAlert ? AppTheme.error : Theme.of(context).cardColor,
        gradient: vital.isAlert
            ? LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).cardColor.withAlpha(200),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20), // More rounded
        boxShadow: [
          BoxShadow(
            color: vital.isAlert
                ? AppTheme.error.withAlpha(80)
                : const Color.fromRGBO(158, 158, 158, 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: vital.isAlert
                  ? Colors.white.withAlpha(50)
                  : vital.color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              vital.icon,
              color: vital.isAlert ? Colors.white : vital.color,
              size: 24, // Larger icon
            ),
          ),
          const SizedBox(height: 16),
          Text(
            vital.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: vital.isAlert ? Colors.white : null,
              fontSize: 20, // Larger font
            ),
          ),
          const SizedBox(height: 4),
          Text(
            vital.label,
            style: TextStyle(
              fontSize: 12,
              color: vital.isAlert
                  ? Colors.white.withAlpha(200)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600]),
              fontWeight: vital.isAlert ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
