/// ─────────────────────────────────────────────────────────────────────────────
/// AppDurations — Standard Non-Animation Durations
///
/// Use [AppAnimationDurations] for animation timings.
/// This file holds broader timing constants (debounce, timeouts, etc.)
/// ─────────────────────────────────────────────────────────────────────────────
library;

abstract final class AppDurations {
  /// 300ms — debounce delay for text input search.
  static const Duration inputDebounce = Duration(milliseconds: 300);

  /// 500ms — debounce delay for heavy operations triggered by UI.
  static const Duration heavyDebounce = Duration(milliseconds: 500);

  /// 5 seconds — snackbar auto-dismiss duration.
  static const Duration snackbar = Duration(seconds: 5);

  /// 3 seconds — toast auto-dismiss duration.
  static const Duration toast = Duration(seconds: 3);

  /// 30 seconds — generic network request timeout (Hybrid mode).
  static const Duration networkTimeout = Duration(seconds: 30);

  /// 2 minutes — long-running file conversion timeout.
  static const Duration conversionTimeout = Duration(minutes: 2);

  /// 10 minutes — maximum allowed background task duration.
  static const Duration backgroundTaskMax = Duration(minutes: 10);
}
