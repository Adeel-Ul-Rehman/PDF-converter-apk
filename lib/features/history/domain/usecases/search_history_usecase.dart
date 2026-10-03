import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SearchHistoryUseCase
/// ─────────────────────────────────────────────────────────────────────────────
class SearchHistoryUseCase {
  const SearchHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  /// Performs instant case-insensitive search by file name, format, or type.
  Future<Result<List<ConversionHistory>>> call(String query) => _repository.searchHistory(query);
}
