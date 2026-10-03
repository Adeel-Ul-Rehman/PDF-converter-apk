import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GetHistoryStatisticsUseCase
/// ─────────────────────────────────────────────────────────────────────────────
class GetHistoryStatisticsUseCase {
  const GetHistoryStatisticsUseCase(this._repository);

  final HistoryRepository _repository;

  /// Aggregates historical metrics (totals, counts, processing sizes and times).
  Future<Result<Map<String, dynamic>>> call() => _repository.getStatistics();
}
