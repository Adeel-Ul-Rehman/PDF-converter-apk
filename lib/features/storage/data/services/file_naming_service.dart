import 'dart:io';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FileNamingService
///
/// Generates safe, collision-free output filenames.
///
/// Rules
/// ─────
/// 1. Sanitize baseName: strip traversal sequences, control chars, leading dots.
/// 2. Enforce maximum filename length (200 chars).
/// 3. If `<dir>/<baseName>.<ext>` exists, try `<baseName> (1).<ext>`, etc.
/// 4. Never overwrite automatically (future: honour an overwrite setting).
/// ─────────────────────────────────────────────────────────────────────────────
class FileNamingService {
  static const int _maxBaseLength = 200;

  /// Returns a safe, non-colliding path: `<dir>/<safeName>.<ext>`.
  String resolve({
    required String directory,
    required String baseName,
    required String extension,
  }) {
    final safe = _sanitize(baseName);
    final ext = extension.toLowerCase().replaceFirst(RegExp(r'^\.'), '');

    var candidate = '$directory/$safe.$ext';
    if (!File(candidate).existsSync()) {
      AppLogger.trace('FileNamingService: resolved → $candidate');
      return candidate;
    }

    var counter = 1;
    while (true) {
      candidate = '$directory/$safe ($counter).$ext';
      if (!File(candidate).existsSync()) {
        AppLogger.trace('FileNamingService: collision resolved → $candidate');
        return candidate;
      }
      counter++;
      if (counter > 9999) {
        // Fallback using timestamp to guarantee uniqueness
        final ts = DateTime.now().millisecondsSinceEpoch;
        candidate = '$directory/${safe}_$ts.$ext';
        AppLogger.warning('FileNamingService: exhausted counter, using timestamp → $candidate');
        return candidate;
      }
    }
  }

  /// Sanitizes a filename base: removes path separators, control chars,
  /// reserved Windows/Unix chars, and leading dots/spaces.
  String _sanitize(String raw) {
    // Strip directory separators (traversal prevention)
    var s = raw.replaceAll(RegExp(r'[/\\]'), '_');
    // Strip null bytes and control characters
    s = s.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    // Strip reserved chars for Windows and Unix
    s = s.replaceAll(RegExp('[<>:"|?*]'), '_');
    // Remove leading dots and spaces
    s = s.replaceAll(RegExp(r'^[\s.]+'), '');
    // Trim trailing dots and spaces (Windows restriction)
    s = s.replaceAll(RegExp(r'[\s.]+$'), '');
    // Enforce max length
    if (s.length > _maxBaseLength) s = s.substring(0, _maxBaseLength);
    // Fallback for empty string
    if (s.isEmpty) s = 'converted_file';
    return s;
  }

  /// Returns the sanitized basename without resolving collisions.
  String sanitize(String raw) => _sanitize(raw);
}
