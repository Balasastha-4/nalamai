import 'dart:ui';
import 'package:flutter/material.dart';

class AmbientGlowBackground extends StatefulWidget {
  final Color primaryGlowColor;
  final Widget child;

  const AmbientGlowBackground({
    super.key,
    required this.primaryGlowColor,
    required this.child,
  });

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Background
        Container(color: Theme.of(context).scaffoldBackgroundColor),

        // Animated Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final sinValue =
                (1.0 + _controller.value) * 0.5; // slow breathing effect
            return Stack(
              children: [
                // Top-Left Orb
                Positioned(
                  top: -100 * sinValue,
                  left: -50,
                  width: 300,
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.primaryGlowColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Bottom-Right Orb
                Positioned(
                  bottom: -150 + (50 * _controller.value),
                  right: -100,
                  width: 350,
                  height: 350,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.primaryGlowColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Heavy Blur layer to create the ambient light effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Main Content
        SafeArea(child: widget.child),
      ],
    );
  }
}
