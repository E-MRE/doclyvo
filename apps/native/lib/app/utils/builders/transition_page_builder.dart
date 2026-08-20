import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class TransitionPageBuilder {
  const TransitionPageBuilder._();

  static const Duration _duration = Duration(milliseconds: 350);
  static const double _startOffsetY = 8;

  /// Fades and slides [child] up on mount, per `design/README.md`'s motion
  /// section (mirrors the web app's `animate-fade-in-up` keyframe). Skips
  /// the animation entirely when the platform requests reduced motion.
  static Page<void> fadeTransition({
    required Widget child,
    Curve curve = Curves.easeOut,
  }) {
    return CustomTransitionPage<void>(
      child: child,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) return child;

        final curved = CurvedAnimation(parent: animation, curve: curve);

        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) {
            return Opacity(
              opacity: curved.value,
              child: Transform.translate(
                offset: Offset(0, _startOffsetY * (1 - curved.value)),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
