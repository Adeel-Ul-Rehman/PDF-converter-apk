/// ─────────────────────────────────────────────────────────────────────────────
/// AppFileConstants — File Upload Limits & Type Configurations
///
/// Centralized rules for supported file extensions and size validation.
/// ─────────────────────────────────────────────────────────────────────────────
library;

abstract final class AppFileConstants {
  /// Maximum file upload size limit = 100 MB in bytes (100 * 1024 * 1024)
  static const int maxFileSizeBytes = 104857600;

  /// Supported Document extensions
  static const Set<String> documentExtensions = {
    'pdf',
    'docx',
    'doc',
    'txt',
    'rtf',
    'epub',
    'xlsx',
    'xls',
    'csv',
    'pptx',
    'ppt',
  };

  /// Supported Image extensions
  static const Set<String> imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'bmp',
    'heic',
    'tiff',
  };

  /// Supported Audio extensions
  static const Set<String> audioExtensions = {
    'mp3',
    'wav',
    'm4a',
    'ogg',
    'flac',
    'aac',
  };

  /// Supported Video extensions
  static const Set<String> videoExtensions = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'flv',
  };

  /// Full set of all supported file extensions
  static final Set<String> allSupportedExtensions = {
    ...documentExtensions,
    ...imageExtensions,
    ...audioExtensions,
    ...videoExtensions,
  };
}
