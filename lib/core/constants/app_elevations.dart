/// ─────────────────────────────────────────────────────────────────────────────
/// AppElevations — Material 3 Elevation Tokens
/// ─────────────────────────────────────────────────────────────────────────────
library;

abstract final class AppElevations {
  /// 0dp — flat surface: scaffold background, cards on surface.
  static const double none = 0;

  /// 1dp — subtle lift: outlined card hover state.
  static const double xs = 1;

  /// 2dp — low lift: default card, list item.
  static const double sm = 2;

  /// 4dp — medium lift: FAB resting, navigation bar.
  static const double md = 4;

  /// 8dp — high lift: FAB pressed, bottom navigation bar.
  static const double lg = 8;

  /// 12dp — modal overlay: bottom sheet, side drawer.
  static const double xl = 12;

  /// 16dp — top-level overlay: dialog, alert.
  static const double xxl = 16;

  /// 24dp — maximum elevation: full-screen modal.
  static const double max = 24;
}
