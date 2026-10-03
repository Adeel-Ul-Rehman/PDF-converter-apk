import 'package:flux_convert/features/document_converter/domain/entities/document_format.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_metadata.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentFile
///
/// Domain entity representing a selected document file.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentFile {
  const DocumentFile({
    required this.filePath,
    required this.format,
    required this.metadata,
  });

  /// Absolute file system path of the document.
  final String filePath;

  /// Format type representation.
  final DocumentFormat format;

  /// Parsed metadata parameters.
  final DocumentMetadata metadata;

  @override
  String toString() => 'DocumentFile($filePath, format=${format.name})';
}
