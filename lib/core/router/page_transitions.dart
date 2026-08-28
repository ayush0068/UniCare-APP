import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A subtle fade + slide-up transition used for top-level screen changes
/// (splash -> role selection -> home/dashboard, login -> home, etc.) so
/// navigating between them feels smooth and modern instead of the default
/// abrupt platform transition — similar to the polished open/close feel
/// apps like YouTube or JioHotstar have.
CustomTransitionPage<void> fadeSlidePage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}