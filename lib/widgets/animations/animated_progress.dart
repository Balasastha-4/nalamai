import 'package:flutter/material.dart';

class AnimatedProgress extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final Duration duration;

  const AnimatedProgress({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.height = 4.0,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return LinearProgressIndicator(
          value: val,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(height / 2),
          minHeight: height,
        );
      },
    );
  }
}
