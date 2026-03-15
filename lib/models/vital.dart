import 'package:flutter/material.dart';

class Vital {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const Vital({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });
}
