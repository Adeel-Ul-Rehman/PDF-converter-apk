/// ─────────────────────────────────────────────────────────────────────────────
/// File Size Utilities
///
/// Utility functions for working with file sizes and byte counts.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class FileSizeUtils {
  /// Formats a byte count as a human-readable string.
  ///
  /// Examples:
  ///   - 512 → "512 B"
  ///   - 1024 → "1.0 KB"
  ///   - 1048576 → "1.0 MB"
  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Returns `true` if [bytes] does not exceed the given [limitBytes].
  static bool isWithinLimit(int bytes, int limitBytes) => bytes <= limitBytes;
}
