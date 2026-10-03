import 'package:mime/mime.dart';
import 'package:flux_convert/core/constants/app_file_constants.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FileTypeDetector — File MIME and Category Resolver
///
/// Inspects file paths or byte arrays to deduce their format category.
/// Uses the mime package.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class FileTypeDetector {
  /// Determines the MIME type string of a file by path name.
  static String? getMimeType(String filePath) => lookupMimeType(filePath);

  /// Matches the file path extension against supported categories.
  static FileCategory detectCategory(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    if (AppFileConstants.imageExtensions.contains(extension)) {
      return FileCategory.image;
    } else if (AppFileConstants.documentExtensions.contains(extension)) {
      return FileCategory.document;
    } else if (AppFileConstants.audioExtensions.contains(extension)) {
      return FileCategory.audio;
    } else if (AppFileConstants.videoExtensions.contains(extension)) {
      return FileCategory.video;
    }

    return FileCategory.unknown;
  }
}

/// Standard types of files supported in FluxConvert.
enum FileCategory {
  document,
  image,
  audio,
  video,
  unknown;

  String get displayName => switch (this) {
        FileCategory.document => 'Document',
        FileCategory.image => 'Image',
        FileCategory.audio => 'Audio',
        FileCategory.video => 'Video',
        FileCategory.unknown => 'Unknown File',
      };
}
