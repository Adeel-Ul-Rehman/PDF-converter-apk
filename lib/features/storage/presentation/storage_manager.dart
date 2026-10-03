import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';
import 'package:flux_convert/features/storage/presentation/providers/storage_providers.dart';

export 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';
export 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';
export 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';
export 'package:flux_convert/features/storage/presentation/providers/storage_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageManager — Public Facade
///
/// Single entry point for all file path, operation, validation, and cleanup
/// requests. No other feature should touch dart:io directly.
/// ─────────────────────────────────────────────────────────────────────────────
class StorageManager {
  StorageManager([ProviderContainer? container]) : _ref = container ?? ProviderContainer();

  final ProviderContainer _ref;

  StorageRepository get _repo => _ref.read(storageRepositoryProvider);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> initialise() async {
    AppLogger.info('StorageManager: initialising');
    await _ref.read(storageNotifierProvider.notifier).initialise();
  }

  // ── Path Resolution ────────────────────────────────────────────────────────

  Future<Result<String>> resolveOutputPath({
    required String baseName,
    required String extension,
  }) =>
      _repo.resolveOutputPath(baseName: baseName, extension: extension);

  Future<Result<String>> resolveTempPath({required String extension}) =>
      _repo.resolveTempPath(extension: extension);

  // ── File Operations ────────────────────────────────────────────────────────

  Future<Result<bool>> fileExists(String path) => _repo.fileExists(path);

  Future<Result<void>> deleteFile(String path) => _repo.deleteFile(path);

  Future<Result<void>> deleteMultipleFiles(List<String> paths) =>
      _repo.deleteMultipleFiles(paths);

  Future<Result<String>> copyFile({
    required String sourcePath,
    required String destinationDir,
  }) =>
      _repo.copyFile(sourcePath: sourcePath, destinationDir: destinationDir);

  Future<Result<String>> moveFile({
    required String sourcePath,
    required String destinationDir,
  }) =>
      _repo.moveFile(sourcePath: sourcePath, destinationDir: destinationDir);

  Future<Result<String>> renameFile({
    required String path,
    required String newBaseName,
  }) =>
      _repo.renameFile(path: path, newBaseName: newBaseName);

  // ── Sharing / Opening ──────────────────────────────────────────────────────

  Future<Result<String>> prepareShareUri(String path) =>
      _repo.prepareShareUri(path);

  Future<Result<void>> openFile(String path) => _repo.openFile(path);

  // ── Validation ─────────────────────────────────────────────────────────────

  Future<Result<bool>> validatePath(String path) => _repo.validatePath(path);

  // ── Cleanup ────────────────────────────────────────────────────────────────

  Future<Result<void>> cleanTemp() => _repo.cleanTemp();
  Future<Result<void>> cleanCache() => _repo.cleanCache();
  Future<Result<void>> cleanAll() => _repo.cleanAll();

  // ── Statistics ─────────────────────────────────────────────────────────────

  Future<Result<StorageStatistics>> getStatistics() =>
      _repo.getStatistics();

  // ── Scanning ───────────────────────────────────────────────────────────────

  Future<Result<List<String>>> scanOrphanTempFiles() =>
      _repo.scanOrphanTempFiles();

  Future<Result<List<String>>> scanMissingConvertedFiles(
    List<String> knownPaths,
  ) =>
      _repo.scanMissingConvertedFiles(knownPaths);

  Future<Result<List<String>>> scanLocalDocuments(String appDocPath) =>
      _repo.scanLocalDocuments(appDocPath: appDocPath);

  // ── Temporary Directory ────────────────────────────────────────────────────

  /// Returns the platform temporary directory (via path_provider).
  Future<Directory> getTemporaryDirectory() =>
      path_provider.getTemporaryDirectory();

  /// Cleans up old cache/temp files that are older than 24 hours.
  Future<void> runTempCleanup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final now = DateTime.now();
      final entities = tempDir.listSync(recursive: true);

      for (final entity in entities) {
        if (entity is File) {
          final stat = entity.statSync();
          final diff = now.difference(stat.modified);
          if (diff.inHours >= 24) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
      AppLogger.info('StorageManager: Completed cache/temporary directory housekeeping.');
    } catch (e) {
      AppLogger.error('StorageManager: Temporary directory housekeeping failed', e);
    }
  }
}

final storageManagerProvider = Provider<StorageManager>((ref) => StorageManager(ref.container));
