/// ─────────────────────────────────────────────────────────────────────────────
/// AppAnimationDurations — Standard Animation Timing Constants
///
/// All animation durations in the app must reference these constants.
/// Changing a duration here updates every widget that uses it.
/// ─────────────────────────────────────────────────────────────────────────────
library;

/// Standard animation duration constants used throughout FluxConvert.
abstract final class AppAnimationDurations {
  /// 100ms — micro-interactions: ripple, checkbox check, icon swap.
  static const Duration instant = Duration(milliseconds: 100);

  /// 150ms — fast transitions: tooltip appear, chip selection.
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — standard UI response: button press, card expand.
  static const Duration normal = Duration(milliseconds: 250);

  /// 350ms — route transitions, modal sheet open/close.
  static const Duration medium = Duration(milliseconds: 350);

  /// 500ms — complex layout shifts, hero transitions.
  static const Duration slow = Duration(milliseconds: 500);

  /// 800ms — entrance animations, splash screen elements.
  static const Duration xSlow = Duration(milliseconds: 800);

  /// 1200ms — loading spinners, progress bar fills, skeleton shimmers.
  static const Duration loading = Duration(milliseconds: 1200);

  /// 2000ms — full splash-to-home transition.
  static const Duration splash = Duration(milliseconds: 2000);
}
