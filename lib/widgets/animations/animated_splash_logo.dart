import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedSplashLogo extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedSplashLogo({super.key, this.size = 120, required this.color});

  @override
  State<AnimatedSplashLogo> createState() => _AnimatedSplashLogoState();
}

class _AnimatedSplashLogoState extends State<AnimatedSplashLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _morphAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 0.0 to 1.0: Cross to Heart
    _morphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOutBack),
      ),
    );

    // Rotate during the morph
    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi * 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // Breathing scale effect at the very end
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
    ]).animate(_controller);

    _controller.repeat();
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
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _MorphingLogoPainter(
                  morphProgress: _morphAnimation.value,
                  color: widget.color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MorphingLogoPainter extends CustomPainter {
  final double morphProgress; // 0.0 = Cross, 1.0 = Heart
  final Color color;

  _MorphingLogoPainter({required this.morphProgress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);

    // We will interpolate between a Medical Cross and a Heart.
    // To do this smoothly, both shapes need roughly the same number of control points in the same relative positions.
    //
    // Medical Cross points (approximate bounds)
    // Top arm, Right arm, Bottom arm, Left arm

    // For simplicity and elegance, instead of point-to-point morphing,
    // we will use overlapping capsules that rotate and shift into a heart shape.

    // A heart is often made of two intersecting circles/capsules rotated at 45 degrees.
    // A cross is made of two intersecting capsules rotated at 0 and 90 degrees.

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Arm 1 (Vertical in Cross, Left-angled in Heart)
    final double angle1 =
        math.pi / 2 * (1 - morphProgress) + (math.pi / 4) * morphProgress;

    // Arm 2 (Horizontal in Cross, Right-angled in Heart)
    const double angle2Cross = 0.0;
    const double angle2Heart = -math.pi / 4;
    final double angle2 =
        angle2Cross * (1 - morphProgress) + angle2Heart * morphProgress;

    // Shift to form the heart cleavage
    final double shiftX = (w * 0.15) * morphProgress;
    final double shiftY = (h * 0.1) * morphProgress;

    // Drawing Arm 1
    canvas.save();
    canvas.translate(-shiftX, shiftY);
    canvas.rotate(angle1);
    _drawCapsule(
      canvas,
      paint,
      w * 0.2,
      h * 0.8 * (1 + 0.1 * morphProgress),
    ); // slightly longer in heart mode
    canvas.restore();

    // Drawing Arm 2
    canvas.save();
    canvas.translate(shiftX, shiftY);
    canvas.rotate(angle2);
    _drawCapsule(canvas, paint, w * 0.2, h * 0.8 * (1 + 0.1 * morphProgress));
    canvas.restore();

    canvas.restore();

    // Ensure there are no unused variables.

    if (morphProgress > 0.5) {
      // Draw a tiny sparkle or accent when it becomes a heart
      final double scale = (morphProgress - 0.5) * 2;
      canvas.drawCircle(
        Offset(w * 0.7, h * 0.3),
        4 * scale,
        paint..color = Colors.white,
      );
    }
  }

  void _drawCapsule(Canvas canvas, Paint paint, double width, double height) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width / 2));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_MorphingLogoPainter oldDelegate) =>
      oldDelegate.morphProgress != morphProgress || oldDelegate.color != color;
}
