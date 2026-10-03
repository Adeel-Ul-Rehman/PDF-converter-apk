import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DeleteHistoryUseCase
/// ─────────────────────────────────────────────────────────────────────────────
class DeleteHistoryUseCase {
  const DeleteHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  /// Deletes a single history record.
  Future<Result<void>> deleteSingle(String id) => _repository.deleteHistoryItem(id);

  /// Deletes multiple history records.
  Future<Result<void>> deleteMultiple(List<String> ids) => _repository.deleteMultipleItems(ids);
}
