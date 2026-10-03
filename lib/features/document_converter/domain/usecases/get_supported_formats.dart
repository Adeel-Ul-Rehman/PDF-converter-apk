import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GetSupportedFormats Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class GetSupportedFormats {
  const GetSupportedFormats(this._repository);

  final DocumentConversionRepository _repository;

  /// Returns the supported output document formats list for a selected input format.
  Future<Result<List<DocumentFormat>>> call(DocumentFormat format) => _repository.getSupportedConversions(format);
}
