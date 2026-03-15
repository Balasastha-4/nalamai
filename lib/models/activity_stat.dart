import 'package:flutter/material.dart';

class ActivityStat {
  final String label;
  final String value;
  final String unit;
  final IconData? icon;
  final Color? color;

  const ActivityStat({
    required this.label,
    required this.value,
    required this.unit,
    this.icon,
    this.color,
  });
}
