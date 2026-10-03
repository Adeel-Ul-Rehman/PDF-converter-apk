import 'dart:io';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CacheManager
///
/// Manages thumbnail, metadata and conversion cache directories.
/// Supports TTL-based expiry and manual flush.
/// ─────────────────────────────────────────────────────────────────────────────
class CacheManager {
  CacheManager({
    required String cacheDir,
    required String thumbnailsDir,
    this.defaultTtl = const Duration(days: 7),
  })  : _cacheDir = cacheDir,
        _thumbnailsDir = thumbnailsDir;

  final String _cacheDir;
  final String _thumbnailsDir;
  final Duration defaultTtl;

  // ── Thumbnail Cache ────────────────────────────────────────────────────────

  /// Returns the cache path for [sourceHash] thumbnail, or null if not cached.
  String? getThumbnailPath(String sourceHash) {
    final path = '$_thumbnailsDir/$sourceHash.png';
    final file = File(path);
    if (!file.existsSync()) return null;
    // Check TTL
    final stat = file.statSync();
    if (DateTime.now().difference(stat.modified) > defaultTtl) {
      file.deleteSync();
      return null;
    }
    return path;
  }

  /// Saves [bytes] as a thumbnail PNG for [sourceHash].
  Future<String> saveThumbnail(String sourceHash, List<int> bytes) async {
    final path = '$_thumbnailsDir/$sourceHash.png';
    await File(path).writeAsBytes(bytes);
    AppLogger.trace('CacheManager: saved thumbnail → $path');
    return path;
  }

  // ── General Cache ──────────────────────────────────────────────────────────

  /// Returns cached bytes for [key], or null if expired / absent.
  List<int>? get(String key) {
    final path = '$_cacheDir/$key';
    final file = File(path);
    if (!file.existsSync()) return null;
    final stat = file.statSync();
    if (DateTime.now().difference(stat.modified) > defaultTtl) {
      file.deleteSync();
      return null;
    }
    return file.readAsBytesSync();
  }

  /// Stores [bytes] under [key] in the cache directory.
  Future<void> put(String key, List<int> bytes) async {
    final path = '$_cacheDir/$key';
    await File(path).writeAsBytes(bytes);
    AppLogger.trace('CacheManager: cached key=$key');
  }

  /// Removes a specific cache entry.
  void evict(String key) {
    final file = File('$_cacheDir/$key');
    if (file.existsSync()) file.deleteSync();
  }

  /// Removes all cached files immediately.
  Future<void> flush() async {
    await _flushDir(_cacheDir, 'cache');
    await _flushDir(_thumbnailsDir, 'thumbnails');
  }

  Future<void> _flushDir(String dir, String label) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return;
    try {
      await for (final entity in directory.list()) {
        if (entity is File) await entity.delete();
      }
      AppLogger.info('CacheManager: flushed $label');
    } on Exception catch (e) {
      AppLogger.warning('CacheManager: flush[$label] error: $e');
    }
  }
}
