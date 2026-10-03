import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FileStorageService — App File Directory Management
///
/// Abstracts file system access for the app's working directories.
/// All features should use this service instead of path_provider directly.
///
/// Injected via Riverpod: use [fileStorageServiceProvider].
/// ─────────────────────────────────────────────────────────────────────────────
class FileStorageService {
  Directory? _appDocDir;
  Directory? _tempDir;

  /// Returns the app's documents directory (persists across sessions).
  Future<Directory> get appDocumentsDir async =>
      _appDocDir ??= await getApplicationDocumentsDirectory();

  /// Returns (and creates if necessary) a named subdirectory inside documents.
  Future<Directory> subdirectory(String name) async {
    final base = await appDocumentsDir;
    final dir = Directory('${base.path}/$name');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
      AppLogger.trace('FileStorageService: created directory → ${dir.path}');
    }
    return dir;
  }

  /// Returns the system temp directory. Files here may be deleted by the OS.
  Future<Directory> get tempDir async =>
      _tempDir ??= await getTemporaryDirectory();

  /// Creates a uniquely-named temp file with the given [extension].
  Future<File> createTempFile(String extension) async {
    final dir = await tempDir;
    final name = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File('${dir.path}/$name');
    AppLogger.trace('FileStorageService: created temp file → ${file.path}');
    return file;
  }

  /// Deletes a single file safely, ignoring errors if it does not exist.
  Future<void> deleteFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
        AppLogger.trace('FileStorageService: deleted → ${file.path}');
      }
    } on FileSystemException catch (e, stack) {
      AppLogger.warning('FileStorageService: delete failed', e, stack);
    }
  }

  /// Deletes all files in the temp directory created by this app.
  Future<void> clearTemp() async {
    final dir = await tempDir;
    AppLogger.warning('FileStorageService: clearing temp dir → ${dir.path}');
    try {
      await for (final entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    } on FileSystemException catch (e, stack) {
      AppLogger.error('FileStorageService: clearTemp failed', e, stack);
    }
  }
}

/// Provides the [FileStorageService] singleton.
final fileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => FileStorageService(),
);
