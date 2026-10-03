import 'package:flux_convert/features/performance/domain/entities/performance_state.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PerformanceRepository — Abstract contract for gathering metrics and executing
/// optimization actions. Implementations live in the data layer.
/// ─────────────────────────────────────────────────────────────────────────────
abstract class PerformanceRepository {
  /// Returns the current performance snapshot.
  Future<PerformanceState> getCurrentState();

  /// Clears caches (thumbnail, memory, etc.) and returns the updated state.
  Future<PerformanceState> clearCaches();

  /// Records a custom metric. Implementations may store it or forward to
  /// debug‑only logger. In release builds it should be a no‑op.
  Future<void> recordMetric(String key, dynamic value);
}
