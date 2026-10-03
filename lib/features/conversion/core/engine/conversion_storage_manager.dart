import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionStorageManager
///
/// Handles target directory path allocations, avoids collisions,
/// and manages cache clearances.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ConversionStorageManager {
  /// Generates a non-colliding destination output path inside the app document directory.
  static Future<Result<String>> getDestinationPath(
    String originalNameWithoutExt,
    String targetExt,
  ) async {
    try {
      final cleanExt = targetExt.replaceAll('.', '').toLowerCase();
      final appDocDir = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${appDocDir.path}/converted');

      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      var destinationPath = '${outputDir.path}/$originalNameWithoutExt.$cleanExt';
      var count = 1;

      // Handle file naming collision resolution (e.g. file_1.pdf, file_2.pdf)
      while (File(destinationPath).existsSync()) {
        destinationPath =
            '${outputDir.path}/${originalNameWithoutExt}_$count.$cleanExt';
        count++;
      }

      return Success(destinationPath);
    } catch (e, stack) {
      return FailureResult(
        StorageError(
          message: 'Unable to allocate destination storage path.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Clears temporary cache directories to free up user storage.
  static Future<Result<void>> clearTempDirectory() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        final cacheEntities = cacheDir.listSync();
        for (final entity in cacheEntities) {
          if (entity is File) {
            entity.deleteSync();
          } else if (entity is Directory) {
            entity.deleteSync(recursive: true);
          }
        }
      }
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        StorageError(
          message: 'Failed to clear temporary storage cache.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
