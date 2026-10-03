import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DetectDocumentType Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class DetectDocumentType {
  const DetectDocumentType(this._repository);

  final DocumentConversionRepository _repository;

  /// Detects the extension and byte signature format of the document file.
  Future<Result<DocumentFormat>> call(String filePath) => _repository.detectFormat(filePath);
}
