import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class AnimatedLoginHeader extends StatefulWidget {
  final Color primaryColor;

  const AnimatedLoginHeader({super.key, required this.primaryColor});

  @override
  State<AnimatedLoginHeader> createState() => _AnimatedLoginHeaderState();
}

class _AnimatedLoginHeaderState extends State<AnimatedLoginHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Use a longer lists of particles so we can initialize them once
  final List<_Particle> _particles = List.generate(15, (index) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // ECG cycle time
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _HealthscapePainter(
            animationValue: _controller.value,
            color: widget.primaryColor,
            isDark: Theme.of(context).brightness == Brightness.dark,
            particles: _particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double xOffset = math.Random().nextDouble();
  final double yOffset = math.Random().nextDouble();
  final double size = math.Random().nextDouble() * 15 + 5;
  final double speed = math.Random().nextDouble() * 0.5 + 0.2;
}

class _HealthscapePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isDark;
  final List<_Particle> particles;

  _HealthscapePainter({
    required this.animationValue,
    required this.color,
    required this.isDark,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final Rect rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: isDark ? 0.3 : 0.4),
          isDark ? const Color(0xFF151520) : color.withValues(alpha: 0.05),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Floating Particles (Health Orbs/Molecules)
    for (var particle in particles) {
      final floatPaint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.3 : 0.4)
        ..style = PaintingStyle.fill;

      // Calculate continuous upward motion wrapping around
      double yPos =
          size.height -
          ((particle.yOffset * size.height +
                  animationValue * particle.speed * size.height) %
              size.height);
      double xPos =
          particle.xOffset * size.width +
          math.sin(animationValue * math.pi * 2 + particle.yOffset * 10) * 20;

      canvas.drawCircle(Offset(xPos, yPos), particle.size, floatPaint);
    }

    // Abstract Background Sine Waves
    _drawSineWave(
      canvas: canvas,
      size: size,
      color: color.withValues(alpha: isDark ? 0.15 : 0.2),
      frequency: 2,
      amplitude: 30,
      yOffset: size.height * 0.4,
      phaseShift: animationValue * math.pi * 2,
      strokeWidth: 4,
    );

    _drawSineWave(
      canvas: canvas,
      size: size,
      color: color.withValues(alpha: isDark ? 0.25 : 0.3),
      frequency: 1.5,
      amplitude: 45,
      yOffset: size.height * 0.55,
      phaseShift: -animationValue * math.pi * 2,
      strokeWidth: 2,
    );

    // Foreground Emphasized ECG Line (Heartbeat)
    _drawECGLine(canvas, size);

    // Bottom solid white/dark mask to make the transition to the card clean
    final bottomRect = Rect.fromLTRB(
      0,
      size.height - 30,
      size.width,
      size.height,
    );
    canvas.drawRect(
      bottomRect,
      Paint()..color = isDark ? const Color(0xFF121212) : Colors.white,
    );
  }

  void _drawSineWave({
    required Canvas canvas,
    required Size size,
    required Color color,
    required double frequency,
    required double amplitude,
    required double yOffset,
    required double phaseShift,
    required double strokeWidth,
  }) {
    final path = Path();
    for (double i = 0; i <= size.width; i++) {
      double y =
          yOffset +
          math.sin((i / size.width * math.pi * 2 * frequency) + phaseShift) *
              amplitude;
      if (i == 0) {
        path.moveTo(i, y);
      } else {
        path.lineTo(i, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawECGLine(Canvas canvas, Size size) {
    final path = Path();
    final double yBase = size.height * 0.75;

    // Simulate an ECG heartbeat pulse that travels across the screen
    // We achieve this by defining a static ECG path and moving a gradient mask over it

    path.moveTo(0, yBase);

    double beatStartX = size.width * 0.45;

    // Straight line before heartbeat
    path.lineTo(beatStartX, yBase);

    // The heartbeat spikes
    path.lineTo(beatStartX + 10, yBase - 15); // P wave
    path.lineTo(beatStartX + 20, yBase);
    path.lineTo(beatStartX + 35, yBase);

    path.lineTo(beatStartX + 42, yBase + 15); // Q
    path.lineTo(beatStartX + 52, yBase - 60); // R (huge spike up)
    path.lineTo(beatStartX + 65, yBase + 30); // S (spike down)
    path.lineTo(beatStartX + 75, yBase);

    path.lineTo(beatStartX + 90, yBase);
    path.lineTo(beatStartX + 105, yBase - 25); // T wave
    path.lineTo(beatStartX + 120, yBase);

    // Straight line to the end
    path.lineTo(size.width, yBase);

    // Create a sweeping gradient to make the line look like it's being drawn / pulsating
    // The pulse moves from left to right based on animationValue
    final double currentPulseX = (animationValue * 1.5 - 0.2) * size.width;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        Offset(currentPulseX - size.width * 0.3, yBase),
        Offset(currentPulseX + size.width * 0.1, yBase),
        [
          color.withValues(alpha: 0.1), // Fading tail
          color.withValues(alpha: 1.0), // Bright head
          color.withValues(alpha: 0.1), // Dark ahead
        ],
        [0.0, 0.9, 1.0],
      );

    // Add glowing shadow behind the line
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HealthscapePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isDark != isDark;
}
