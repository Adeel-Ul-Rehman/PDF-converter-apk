import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// EstimateOutputSize Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class EstimateOutputSize {
  const EstimateOutputSize(this._repository);

  final DocumentConversionRepository _repository;

  /// Estimates the size of the final conversion output.
  Future<Result<int>> call(String filePath, DocumentFormat targetFormat) => _repository.estimateOutputSize(filePath, targetFormat);
}
