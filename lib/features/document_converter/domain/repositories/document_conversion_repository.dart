import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_metadata.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_request.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_validation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionRepository
///
/// Repository contract defining document analysis, validation and parsing interfaces.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class DocumentConversionRepository {
  /// Validates document parameters (permissions, structure, sizes, password locks).
  Future<Result<DocumentValidation>> validateDocument(String filePath);

  /// Analyzes file bytes to resolve document format types.
  Future<Result<DocumentFormat>> detectFormat(String filePath);

  /// Fetches the supported outputs list mapped by the conversion matrix.
  Future<Result<List<DocumentFormat>>> getSupportedConversions(DocumentFormat format);

  /// Allocates cache folders and handles target naming collision paths.
  Future<Result<String>> prepareConversion(String filePath, DocumentFormat targetFormat);

  /// Executes conversion, notifying callbacks on progress updates (0.0 to 1.0).
  Future<Result<DocumentConversionResponse>> convert(
    DocumentConversionRequest request,
    void Function(double progress) onProgress,
  );

  /// Cancels ongoing conversions for the requested task ID.
  Future<Result<void>> cancelConversion(String taskId);

  /// Estimates output document file size.
  Future<Result<int>> estimateOutputSize(String filePath, DocumentFormat targetFormat);

  /// Parses file descriptors to populate document metadata.
  Future<Result<DocumentMetadata>> extractMetadata(String filePath);
}
