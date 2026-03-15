import 'package:flutter/material.dart';

class HealthTip {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const HealthTip({
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.blue,
  });
}
