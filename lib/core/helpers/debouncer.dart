import 'dart:async';
import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Debouncer — Event execution delay helper
///
/// Prevents rapid successions of callbacks by adding a delay timer.
/// Essential for text searches, quick button clicks, and resize handlers.
/// ─────────────────────────────────────────────────────────────────────────────
class Debouncer {
  Debouncer({required this.milliseconds});

  final int milliseconds;
  Timer? _timer;

  /// Run [action] after the debounced time duration.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancels any active timer schedule.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
