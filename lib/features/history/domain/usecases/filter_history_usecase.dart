import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FilterHistoryUseCase
/// ─────────────────────────────────────────────────────────────────────────────
class FilterHistoryUseCase {
  const FilterHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  /// Filters history by format group, status, or date days limit ranges.
  Future<Result<List<ConversionHistory>>> call({
    String? formatGroup,
    String? status,
    int? daysLimit,
  }) => _repository.filterHistory(
      formatGroup: formatGroup,
      status: status,
      daysLimit: daysLimit,
    );
}
