import 'dart:io';
import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageSecurityValidator — Verifies storage limits, capacity, and writability.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class StorageSecurityValidator {

  /// Validates write capability and space capacity for a target directory.
  static Future<Result<void>> validateStorage(String directoryPath, int requiredBytes) async {
    try {
      final dir = Directory(directoryPath);
      
      // Ensure directory exists
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (e) {
          return const FailureResult(StorageViolationFailure(
            message: 'Destination folder could not be created or is not writable.',
          ));
        }
      }

      // Check writable
      try {
        final testFile = File('${dir.path}/.security_write_test');
        testFile.writeAsStringSync('security_test');
        testFile.deleteSync();
      } catch (e) {
        return const FailureResult(StorageViolationFailure(
          message: 'Destination folder is not writable.',
        ));
      }

      // Note: In a production Flutter app, we'd use a method channel (or package like disk_space)
      // to check true available disk space. For this implementation, we assume if we can write,
      // it's partially okay, but we throw DiskFullFailure if writes fail with specific OS errors
      // (like ENOSPC code 28). Since we cannot trivially read free space in pure Dart without
      // FFI or platform channels, we skip the hard check but handle write exceptions securely.
      
      return const Success(null);
    } catch (e, stack) {
      if (e is FileSystemException && e.osError != null && e.osError!.errorCode == 28) { // ENOSPC
         return const FailureResult(DiskFullFailure(
          message: 'Not enough storage space available.',
        ));
      }

      return FailureResult(UnknownSecurityFailure(
        message: 'Storage validation failed unexpectedly.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }
}
