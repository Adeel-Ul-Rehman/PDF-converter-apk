import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentCacheManager
///
/// Handles managing temporary file allocations, pruning expired document copies
/// after threshold delays, and final cash removals.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class DocumentCacheManager {
  static const String _subFolder = 'document_cache';

  static Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_subFolder');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    return cacheDir;
  }

  /// Writes a temporary file inside the cache folder.
  static Future<File> writeTempFile(String fileName, List<int> bytes) async {
    final cacheDir = await _getCacheDirectory();
    final tempFile = File('${cacheDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// Allocates a target output path in the cache directory.
  static Future<String> allocateOutputPath(String fileName) async {
    final cacheDir = await _getCacheDirectory();
    return '${cacheDir.path}/$fileName';
  }

  /// Iterates and deletes all cached documents older than [maxAge].
  static Future<void> pruneExpiredCache(Duration maxAge) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final entities = cacheDir.listSync();
      final now = DateTime.now();

      for (final entity in entities) {
        if (entity is File) {
          final stat = entity.statSync();
          final age = now.difference(stat.modified);
          if (age > maxAge) {
            entity.deleteSync();
            AppLogger.info('DocumentCacheManager: Deleted expired cache file: ${entity.path}');
          }
        }
      }
    } catch (e, stack) {
      AppLogger.error('DocumentCacheManager: Failed to prune expired caches.', e, stack);
    }
  }

  /// Completely wipes all files in the document cache folder.
  static Future<void> clearAll() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        AppLogger.info('DocumentCacheManager: Wiped all temporary caches.');
      }
    } catch (e, stack) {
      AppLogger.error('DocumentCacheManager: Failed to clear cache directory.', e, stack);
    }
  }
}
