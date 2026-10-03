import 'package:flux_convert/features/document_converter/domain/entities/document_file.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionRequest
///
/// Contains parameters detailing document conversion settings.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentConversionRequest {
  const DocumentConversionRequest({
    required this.document,
    required this.targetFormat,
    required this.outputDirectory,
    this.keepMetadata = true,
    this.compressOutput = false,
    this.password,
  });

  /// Target document file to be parsed.
  final DocumentFile document;

  /// Target output format extension.
  final DocumentFormat targetFormat;

  /// Target file path output directory.
  final String outputDirectory;

  /// Keep metadata parameters in target output files.
  final bool keepMetadata;

  /// Compress target output document files if possible.
  final bool compressOutput;

  /// Password key if the document requires decryption.
  final String? password;
}
