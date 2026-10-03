import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CancelConversion Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class CancelConversion {
  const CancelConversion(this._repository);

  final DocumentConversionRepository _repository;

  /// Aborts and cancels ongoing conversion operations.
  Future<Result<void>> call(String taskId) => _repository.cancelConversion(taskId);
}
