import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page transition for every pushed screen: a short fade with a slight
/// rise, the same on web and mobile, so navigation feels like one app
/// instead of the platform default.
CustomTransitionPage<T> kayloPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.055, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
