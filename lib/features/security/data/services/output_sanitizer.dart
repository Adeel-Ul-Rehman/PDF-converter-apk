import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/data/services/input_sanitizer.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// OutputSanitizer — Secures generated files before persistence.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class OutputSanitizer {
  /// Generates a safe, unique, guaranteed-to-be-writable output path.
  static Future<Result<String>> resolveSafeOutputPath({
    required String directoryPath,
    required String desiredBaseName,
    required String requiredExtension,
    bool allowOverwrite = false,
  }) async {
    try {
      final dir = Directory(directoryPath);
      if (!dir.existsSync()) {
        return const FailureResult(OutputError(message: 'Output directory does not exist.'));
      }

      final safeBaseName = InputSanitizer.sanitizeFilename(desiredBaseName);
      final cleanExtension = requiredExtension.trim().toLowerCase().replaceAll('.', '');
      
      if (cleanExtension.isEmpty) {
        return const FailureResult(OutputError(message: 'Cannot generate output without a valid extension.'));
      }

      var testPath = p.join(directoryPath, '$safeBaseName.$cleanExtension');
      var file = File(testPath);

      if (!allowOverwrite) {
        // Find a unique name
        var counter = 1;
        while (file.existsSync()) {
          testPath = p.join(directoryPath, '${safeBaseName}_$counter.$cleanExtension');
          file = File(testPath);
          counter++;
          
          if (counter > 1000) {
            return const FailureResult(OutputError(
              message: 'Failed to generate a unique filename after 1000 attempts.',
            ));
          }
        }
      }

      return Success(testPath);
    } catch (e, stack) {
      return FailureResult(UnknownSecurityFailure(
        message: 'Output sanitization failed.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }
}
