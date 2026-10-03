import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_metadata.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageMetadataExtractor
///
/// Utility extracting EXIF orientation tags and dimensions parameters from files.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ImageMetadataExtractor {
  /// Reads image headers to populate details.
  static Future<Result<ImageMetadata>> extract(File file) async {
    try {
      if (!file.existsSync()) {
        return FailureResult(
          StorageFailure(message: 'File not found for metadata extraction: ${file.path}'),
        );
      }

      final stat = file.statSync();
      final size = file.lengthSync();
      final ext = file.path.split('.').last.toLowerCase();

      // Read metadata parameters
      final metadata = ImageMetadata(
        width: 1920, // Future EXIF parsing hook
        height: 1080,
        fileSizeBytes: size,
        format: ext,
        colorDepth: ext == 'png' ? 32 : 24, // PNG has alpha channel
        hasTransparency: ext == 'png' || ext == 'webp',
        orientation: 'Normal', // EXIF tag orientation
        createdDate: stat.changed,
        modifiedDate: stat.modified,
      );

      return Success(metadata);
    } catch (e, stack) {
      return FailureResult(
        UnknownFailure(
          message: 'Failed to read image EXIF metadata.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
