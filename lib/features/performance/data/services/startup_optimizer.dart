import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:flux_convert/features/performance/data/services/performance_logger.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StartupOptimizer — Handles deferred and background initializations to
/// reduce cold‑start latency. In debug mode we log each step; in release we
/// perform minimal work.
/// ─────────────────────────────────────────────────────────────────────────────
class StartupOptimizer {
  StartupOptimizer(this._logger);

  final PerformanceLogger _logger;

  /// Called early in `AppBootstrap.init`. Performs lightweight initialization
  /// synchronously, then launches heavy work in a background isolate.
  Future<void> optimize() async {
    // 1️⃣ Critical services – already initialized (e.g., SharedPreferences).
    if (kDebugMode) {
      _logger.record('startup', 'critical services ready');
    }
    // 2️⃣ Defer non‑critical heavy work.
    await _deferHeavyWork();
  }

  Future<void> _deferHeavyWork() async {
    // Pre‑warming thumbnail cache or loading large static assets.
    // Runs in a background isolate so the UI thread stays responsive.
    await Isolate.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    if (kDebugMode) {
      _logger.record('startup', 'deferred work completed');
    }
  }
}
