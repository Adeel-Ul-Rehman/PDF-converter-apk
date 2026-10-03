import 'package:flux_convert/features/performance/domain/repositories/performance_repository.dart';
import 'package:flux_convert/features/performance/domain/entities/performance_state.dart';
import 'package:flux_convert/features/performance/data/services/performance_logger.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PerformanceRepositoryImpl — Concrete implementation that records metrics via
/// PerformanceLogger and provides a simple cache‑clear operation.
/// ─────────────────────────────────────────────────────────────────────────────
class PerformanceRepositoryImpl implements PerformanceRepository {
  PerformanceRepositoryImpl(this._logger);

  final PerformanceLogger _logger;

  @override
  Future<PerformanceState> getCurrentState() async {
    // In a real app this would aggregate metrics from various services.
    // For now we return a default snapshot.
    return const PerformanceState();
  }

  @override
  Future<PerformanceState> clearCaches() async {
    // Clear any cached resources; stub for now.
    await _logger.clearAll();
    return const PerformanceState();
  }

  @override
  Future<void> recordMetric(String key, dynamic value) async {
    await _logger.record(key, value);
  }
}
