import 'package:flux_convert/core/constants/app_file_constants.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Validators — Central input validation logic
///
/// Contains reusable validation rules for strings, email/text inputs, and files.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class Validators {
  /// Validates that a filename contains safe characters and isn't blank.
  static bool isValidFileName(String name) {
    if (name.trim().isEmpty) return false;
    // Disallow invalid characters common on file systems (e.g. / \ : * ? " < > |)
    final regex = RegExp(r'[\\/:*?"<>|]');
    return !regex.hasMatch(name);
  }

  /// Checks if a file size falls within the maximum permitted limit.
  static bool isWithinUploadLimit(int sizeInBytes) => sizeInBytes <= AppFileConstants.maxFileSizeBytes;

  /// Checks if the file extension is officially supported by the app.
  static bool isSupportedExtension(String filePath) {
    if (filePath.isEmpty) return false;
    final parts = filePath.split('.');
    if (parts.length < 2) return false;
    final extension = parts.last.toLowerCase();
    return AppFileConstants.allSupportedExtensions.contains(extension);
  }

  /// Generic required validator.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
