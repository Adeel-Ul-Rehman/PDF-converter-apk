import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PrepareConversion Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class PrepareConversion {
  const PrepareConversion(this._repository);

  final DocumentConversionRepository _repository;

  /// Prepares outputs, folder paths, and collision checks.
  Future<Result<String>> call(String filePath, DocumentFormat targetFormat) => _repository.prepareConversion(filePath, targetFormat);
}
