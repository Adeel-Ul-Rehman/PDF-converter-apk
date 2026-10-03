/// ─────────────────────────────────────────────────────────────────────────────
/// AppBorderRadius — Standard Border Radius Tokens
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter/material.dart';

abstract final class AppBorderRadius {
  /// 4dp — tiny: chip labels, tag badges.
  static const double xs = 4;

  /// 8dp — small: buttons (secondary), input fields.
  static const double sm = 8;

  /// 12dp — medium: cards, contained buttons.
  static const double md = 12;

  /// 16dp — large: bottom sheets, dialogs, modals.
  static const double lg = 16;

  /// 20dp — extra-large: feature cards, hero containers.
  static const double xl = 20;

  /// 24dp — 2xL: large panels.
  static const double xxl = 24;

  /// 100dp — full: avatars, FAB, pill buttons.
  static const double full = 100;

  // ── BorderRadius objects (convenience) ────────────────────────────────────
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusFull =
      BorderRadius.all(Radius.circular(full));
}
