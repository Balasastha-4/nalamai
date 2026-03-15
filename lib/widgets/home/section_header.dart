import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String actionText;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTap,
    this.actionText = 'See All',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
