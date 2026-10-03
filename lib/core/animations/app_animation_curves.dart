/// ─────────────────────────────────────────────────────────────────────────────
/// AppAnimationCurves — Standard Easing Curve Constants
///
/// All animation curves must reference these constants.
/// Provides consistent motion language across the entire app.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';

/// Standard easing curves used throughout FluxConvert.
abstract final class AppAnimationCurves {
  /// Standard Material 3 default ease — use for most transitions.
  static const Curve standard = Curves.easeInOut;

  /// Fast decelerate — for elements entering the screen.
  static const Curve enter = Curves.easeOut;

  /// Fast accelerate — for elements leaving the screen.
  static const Curve exit = Curves.easeIn;

  /// Emphasized spring — for playful interactions (FAB, hero).
  static const Curve spring = Curves.elasticOut;

  /// Sharp linear — for progress indicators and loaders.
  static const Curve linear = Curves.linear;

  /// Emphasized decelerate — for drawer/bottom sheet open.
  static const Curve emphasizedDecelerate = Curves.fastOutSlowIn;

  /// Emphasized accelerate — for drawer/bottom sheet close.
  static const Curve emphasizedAccelerate = Curves.fastLinearToSlowEaseIn;

  /// Bounce — for success/completion feedback.
  static const Curve bounce = Curves.bounceOut;
}
