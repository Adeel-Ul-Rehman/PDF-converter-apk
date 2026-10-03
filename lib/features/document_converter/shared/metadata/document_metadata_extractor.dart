import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_metadata.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentMetadataExtractor
///
/// Utility extracting creation/modification dates and details from files.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DocumentMetadataExtractor {
  /// Reads native file attributes and extracts metadata details.
  static Future<Result<DocumentMetadata>> extract(File file) async {
    try {
      if (!file.existsSync()) {
        return FailureResult(
          UnknownFailure(message: 'File not found at path: ${file.path}'),
        );
      }

      final stat = file.statSync();
      final path = file.path;
      final fileName = path.split('/').last.split(r'\').last;
      final ext = fileName.split('.').last.toLowerCase();
      final size = file.lengthSync();

      // Parse metadata
      final metadata = DocumentMetadata(
        fileName: fileName,
        extension: ext,
        sizeBytes: size,
        author: 'Unknown Creator', // Future extraction hook
        createdDate: stat.changed,
        modifiedDate: stat.modified,
      );

      return Success(metadata);
    } catch (e, stack) {
      return FailureResult(
        UnknownFailure(
          message: 'Failed to extract file metadata.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
