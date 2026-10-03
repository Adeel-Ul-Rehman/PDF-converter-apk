import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SaveConversionUseCase
/// ─────────────────────────────────────────────────────────────────────────────
class SaveConversionUseCase {
  const SaveConversionUseCase(this._repository);

  final HistoryRepository _repository;

  /// Saves a completed [ConversionHistory] record.
  Future<Result<void>> call(ConversionHistory history) => _repository.saveConversion(history);
}
