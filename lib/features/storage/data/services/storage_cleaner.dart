import 'dart:io';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageCleaner
///
/// Deletes expired temp and cache files.
/// Called automatically on app startup and on manual trigger.
/// ─────────────────────────────────────────────────────────────────────────────
class StorageCleaner {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Removes all files in [tempDir] older than [maxAge]. Returns cleaned bytes.
  Future<int> cleanTemp(
    String tempDir, {
    Duration maxAge = const Duration(hours: 1),
  }) =>
      _cleanDirectory(tempDir, maxAge: maxAge, label: 'Temp');

  /// Removes all files in [cacheDir] older than [maxAge]. Returns cleaned bytes.
  Future<int> cleanCache(
    String cacheDir, {
    Duration maxAge = const Duration(days: 7),
  }) =>
      _cleanDirectory(cacheDir, maxAge: maxAge, label: 'Cache');

  /// Deletes an explicit list of file paths.
  Future<int> cleanFiles(List<String> paths) async {
    var bytes = 0;
    for (final path in paths) {
      final file = File(path);
      try {
        if (file.existsSync()) {
          bytes += file.statSync().size;
          await file.delete();
          AppLogger.trace('StorageCleaner: deleted $path');
        }
      } on Exception catch (e) {
        AppLogger.warning('StorageCleaner: failed to delete $path: $e');
      }
    }
    AppLogger.info('StorageCleaner: cleaned ${_toKb(bytes)} KB');
    return bytes;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<int> _cleanDirectory(
    String dir, {
    required Duration maxAge,
    required String label,
  }) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return 0;

    var cleaned = 0;
    final cutoff = DateTime.now().subtract(maxAge);

    try {
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        try {
          final stat = entity.statSync();
          if (stat.modified.isBefore(cutoff)) {
            cleaned += stat.size;
            await entity.delete();
            AppLogger.trace('StorageCleaner[$label]: removed ${entity.path}');
          }
        } on Exception catch (_) {}
      }
    } on Exception catch (e) {
      AppLogger.error('StorageCleaner[$label]: scan failed: $e');
    }

    AppLogger.info('StorageCleaner[$label]: freed ${_toKb(cleaned)} KB');
    return cleaned;
  }

  String _toKb(int bytes) => (bytes / 1024).toStringAsFixed(1);
}
