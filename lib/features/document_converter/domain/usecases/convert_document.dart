import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_request.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/domain/repositories/document_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConvertDocument Use Case
/// ─────────────────────────────────────────────────────────────────────────────
class ConvertDocument {
  const ConvertDocument(this._repository);

  final DocumentConversionRepository _repository;

  /// Executes conversion pipeline using registered adapters.
  Future<Result<DocumentConversionResponse>> call(
    DocumentConversionRequest request,
    void Function(double progress) onProgress,
  ) => _repository.convert(request, onProgress);
}
