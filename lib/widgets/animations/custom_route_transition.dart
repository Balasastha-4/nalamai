import 'package:flutter/material.dart';

class CustomRouteTransition<T> extends PageRouteBuilder<T> {
  final Widget page;

  CustomRouteTransition({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      );
}
