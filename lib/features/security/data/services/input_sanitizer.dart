/// ─────────────────────────────────────────────────────────────────────────────
/// InputSanitizer — Strips malicious/invalid content from user-provided input.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class InputSanitizer {
  // Common illegal characters for Windows, Linux, and macOS
  static final RegExp _illegalFilenameCharacters = RegExp(r'[<>:"/\\|?*]');
  // Control characters
  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1F\x7F]');

  /// Sanitizes a filename, stripping path elements, illegal chars, and trimming.
  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'untitled';

    // 1. Remove path separators if provided
    var clean = filename.replaceAll(RegExp(r'[/\\]'), '_');

    // 2. Remove control characters
    clean = clean.replaceAll(_controlCharacters, '');

    // 3. Replace illegal filename characters with underscores
    clean = clean.replaceAll(_illegalFilenameCharacters, '_');

    // 4. Trim leading/trailing whitespace and dots
    clean = clean.trim();
    while (clean.startsWith('.')) {
      clean = clean.substring(1).trim();
    }
    while (clean.endsWith('.')) {
      clean = clean.substring(0, clean.length - 1).trim();
    }

    if (clean.isEmpty) return 'untitled';

    // 5. Ensure maximum safe length (e.g., 255 chars is a common OS limit)
    // We leave room for extensions. Let's cap the base name at 200 chars.
    if (clean.length > 200) {
      clean = clean.substring(0, 200);
    }

    return clean;
  }

  /// Sanitizes generic user input text.
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';

    // Remove control characters (except common whitespace like \n, \t)
    final sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
    
    return sanitized.trim();
  }
}
