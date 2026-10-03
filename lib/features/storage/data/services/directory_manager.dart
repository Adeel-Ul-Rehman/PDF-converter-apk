import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DirectoryManager
///
/// Creates and verifies all FluxConvert subdirectories on startup.
/// Returns a fully-resolved [StoragePathConfig].
/// ─────────────────────────────────────────────────────────────────────────────
class DirectoryManager {
  StoragePathConfig? _cachedConfig;

  /// Clears the cached directory configuration.
  void clearCache() {
    _cachedConfig = null;
  }

  /// Resolves and creates the full directory tree. Cached after first call.
  Future<StoragePathConfig> ensureAll() async {
    if (_cachedConfig != null) return _cachedConfig!;

    final base = await getApplicationDocumentsDirectory();
    final root = '${base.path}/FluxConvert';

    final prefs = await SharedPreferences.getInstance();
    final customSaveLoc = prefs.getString('custom_save_location');

    final String convertedDocsPath;
    final String convertedImgsPath;

    if (customSaveLoc != null && customSaveLoc.isNotEmpty) {
      convertedDocsPath = customSaveLoc;
      convertedImgsPath = customSaveLoc;
    } else {
      convertedDocsPath = '$root/Converted/Documents';
      convertedImgsPath = '$root/Converted/Images';
    }

    final paths = {
      'root': root,
      'convertedDocuments': convertedDocsPath,
      'convertedImages': convertedImgsPath,
      'temp': '$root/Temp',
      'cache': '$root/Cache',
      'logs': '$root/Logs',
      'exports': '$root/Exports',
      'history': '$root/History',
      'thumbnails': '$root/Thumbnails',
      'scans': '$root/Temp/Scans',
    };

    for (final entry in paths.entries) {
      final dir = Directory(entry.value);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
        AppLogger.trace('DirectoryManager: created ${entry.key} → ${entry.value}');
      }
    }

    _cachedConfig = StoragePathConfig(
      rootPath: paths['root']!,
      convertedDocumentsPath: paths['convertedDocuments']!,
      convertedImagesPath: paths['convertedImages']!,
      tempPath: paths['temp']!,
      cachePath: paths['cache']!,
      logsPath: paths['logs']!,
      exportsPath: paths['exports']!,
      historyPath: paths['history']!,
      thumbnailsPath: paths['thumbnails']!,
      scansTempPath: paths['scans']!,
    );

    AppLogger.info('DirectoryManager: all directories ready');
    return _cachedConfig!;
  }

  /// Invalidates the cached config (e.g. after moving the app storage).
  void invalidateCache() => _cachedConfig = null;
}
