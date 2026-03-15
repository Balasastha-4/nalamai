import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DailySummaryCard extends StatelessWidget {
  final int wellnessScore;
  final int scoreChange; // e.g. +2
  final double progressValue; // 0.0 to 1.0

  const DailySummaryCard({
    super.key,
    required this.wellnessScore,
    required this.scoreChange,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wellness Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$wellnessScore',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '${scoreChange > 0 ? '+' : ''}$scoreChange% vs yesterday',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
