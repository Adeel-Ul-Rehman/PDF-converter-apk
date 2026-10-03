import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_validation.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ValidateDocument Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class ValidateDocument {
  const ValidateDocument(this._repository);

  final DocumentConversionRepository _repository;

  /// Executes validation checks on the selected document file.
  Future<Result<DocumentValidation>> call(String filePath) => _repository.validateDocument(filePath);
}
