/// ─────────────────────────────────────────────────────────────────────────────
/// AppTransitions — Reusable Page & Widget Transition Helpers
///
/// Provides factory methods for common transition types.
/// Use these instead of creating ad-hoc [PageRouteBuilder] instances.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flux_convert/core/animations/app_animation_curves.dart';
import 'package:flux_convert/core/animations/app_animation_durations.dart';

/// Factory class for building common page and widget transitions.
abstract final class AppTransitions {
  /// Fade transition — use for modal pages and overlays.
  static Widget fade({
    required Animation<double> animation,
    required Widget child,
  }) =>
      FadeTransition(opacity: animation, child: child);

  /// Scale + fade transition — use for dialogs and bottom sheets.
  static Widget scaleFade({
    required Animation<double> animation,
    required Widget child,
  }) =>
      ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: AppAnimationCurves.spring,
        ),
        child: FadeTransition(opacity: animation, child: child),
      );

  /// Slide-up transition — use for bottom navigation tab changes.
  static Widget slideUp({
    required Animation<double> animation,
    required Widget child,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppAnimationCurves.enter,
          ),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );

  /// Slide-right transition — use for push navigation.
  static Widget slideRight({
    required Animation<double> animation,
    required Widget child,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppAnimationCurves.enter,
          ),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );

  /// Custom [GoRouter] transition builder for fade-in on route change.
  static CustomTransitionPage<void> fadeTransitionPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: AppAnimationDurations.medium,
        reverseTransitionDuration: AppAnimationDurations.fast,
        transitionsBuilder: (context, animation, secondary, child) =>
            fade(animation: animation, child: child),
      );
}
