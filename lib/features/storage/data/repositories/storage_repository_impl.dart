import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';
import 'package:flux_convert/features/storage/data/services/cache_manager.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';
import 'package:flux_convert/features/storage/data/services/file_naming_service.dart';
import 'package:flux_convert/features/storage/data/services/storage_cleaner.dart';
import 'package:flux_convert/features/storage/data/services/storage_scanner.dart';
import 'package:flux_convert/features/storage/data/services/storage_statistics_service.dart';
import 'package:flux_convert/features/storage/data/services/storage_validator.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageRepositoryImpl — Concrete Storage Repository
/// ─────────────────────────────────────────────────────────────────────────────
class StorageRepositoryImpl implements StorageRepository {
  StorageRepositoryImpl({
    required this.directoryManager,
    required this.namingService,
    required this.scanner,
    required this.cleaner,
    required this.statisticsService,
  });

  final DirectoryManager directoryManager;
  final FileNamingService namingService;
  final StorageScanner scanner;
  final StorageCleaner cleaner;
  final StorageStatisticsService statisticsService;

  StoragePathConfig? _config;
  late final StorageValidator _validator;
  late final CacheManager _cacheManager;

  /// Clears the cached directory configuration in repository and directory manager.
  void clearCache() {
    _config = null;
    directoryManager.clearCache();
  }

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  @override
  Future<Result<StoragePathConfig>> ensureDirectories() async {
    try {
      _config = await directoryManager.ensureAll();
      _validator = StorageValidator(appRootPath: _config!.rootPath);
      _cacheManager = CacheManager(
        cacheDir: _config!.cachePath,
        thumbnailsDir: _config!.thumbnailsPath,
      );
      return Success(_config!);
    } catch (e, stack) {
      AppLogger.error('StorageRepo: ensureDirectories failed', e, stack);
      return FailureResult(StorageFailure(
        message: 'Failed to initialise storage directories',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  // ── Path Resolution ────────────────────────────────────────────────────────

  @override
  Future<Result<String>> resolveOutputPath({
    required String baseName,
    required String extension,
  }) async {
    try {
      final config = await _requireConfig();
      final dir = config.resolveOutputDirectory(extension);
      final path = namingService.resolve(
        directory: dir,
        baseName: baseName,
        extension: extension,
      );
      final validation = _validator.validateOutputPath(path);
      if (!validation.isValid) return FailureResult(validation.toFailure());
      return Success(path);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Failed to resolve output path',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<String>> resolveTempPath({required String extension}) async {
    try {
      final config = await _requireConfig();
      final ts = DateTime.now().millisecondsSinceEpoch;
      return Success('${config.tempPath}/tmp_$ts.$extension');
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Failed to resolve temp path',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  // ── File Operations ────────────────────────────────────────────────────────

  @override
  Future<Result<bool>> fileExists(String path) async {
    try {
      return Success(File(path).existsSync());
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Failed to check file existence',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> deleteFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
      AppLogger.info('StorageRepo: deleted $path');
      return const Success(null);
    } on FileSystemException catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Failed to delete file',
        technicalMessage: e.message,
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> deleteMultipleFiles(List<String> paths) async {
    try {
      for (final path in paths) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
      AppLogger.info('StorageRepo: deleted ${paths.length} files');
      return const Success(null);
    } on FileSystemException catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Failed to delete files',
        technicalMessage: e.message,
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<String>> copyFile({
    required String sourcePath,
    required String destinationDir,
  }) async {
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) {
        return FailureResult(
          MissingFileFailure(message: 'Source file not found: $sourcePath'),
        );
      }
      final destPath = '$destinationDir/${src.uri.pathSegments.last}';
      await src.copy(destPath);
      AppLogger.info('StorageRepo: copied → $destPath');
      return Success(destPath);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Copy failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<String>> moveFile({
    required String sourcePath,
    required String destinationDir,
  }) async {
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) {
        return FailureResult(
          MissingFileFailure(message: 'Source file not found: $sourcePath'),
        );
      }
      final destPath = '$destinationDir/${src.uri.pathSegments.last}';
      await src.rename(destPath);
      AppLogger.info('StorageRepo: moved → $destPath');
      return Success(destPath);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Move failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<String>> renameFile({
    required String path,
    required String newBaseName,
  }) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return FailureResult(
          MissingFileFailure(message: 'File not found: $path'),
        );
      }
      final dir = file.parent.path;
      final ext = path.split('.').last;
      final safeName = namingService.sanitize(newBaseName);
      final newPath =
          namingService.resolve(directory: dir, baseName: safeName, extension: ext);
      await file.rename(newPath);
      AppLogger.info('StorageRepo: renamed → $newPath');
      return Success(newPath);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Rename failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  // ── Sharing / Opening ──────────────────────────────────────────────────────

  @override
  Future<Result<String>> prepareShareUri(String path) async {
    if (!File(path).existsSync()) {
      return FailureResult(
        MissingFileFailure(message: 'File not found: $path'),
      );
    }
    try {
      await Share.shareXFiles([XFile(path)], text: 'Check out this converted document!');
      return Success(path);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Share failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> openFile(String path) async {
    if (!File(path).existsSync()) {
      return FailureResult(
        MissingFileFailure(message: 'File not found: $path'),
      );
    }
    try {
      final res = await OpenFilex.open(path);
      if (res.type == ResultType.done) {
        return const Success(null);
      } else {
        return FailureResult(StorageFailure(
          message: 'Could not open file: ${res.message}',
        ));
      }
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Could not open file',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  @override
  Future<Result<bool>> validatePath(String path) async {
    await _requireConfig();
    final result = _validator.validateInputPath(path);
    if (!result.isValid) return FailureResult(result.toFailure());
    return const Success(true);
  }

  // ── Cache ──────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> cleanCache() async {
    try {
      final config = await _requireConfig();
      await cleaner.cleanCache(config.cachePath);
      await _cacheManager.flush();
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Cache clean failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> cleanTemp() async {
    try {
      final config = await _requireConfig();
      await cleaner.cleanTemp(config.tempPath);
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Temp clean failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> cleanAll() async {
    final cacheResult = await cleanCache();
    if (cacheResult.isFailure) return cacheResult;
    return cleanTemp();
  }

  // ── Statistics ─────────────────────────────────────────────────────────────

  @override
  Future<Result<StorageStatistics>> getStatistics() async {
    try {
      final config = await _requireConfig();
      final stats = await statisticsService.compute(
        convertedDocumentsPath: config.convertedDocumentsPath,
        convertedImagesPath: config.convertedImagesPath,
        cachePath: config.cachePath,
        tempPath: config.tempPath,
        historyPath: config.historyPath,
      );
      return Success(stats);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Failed to compute storage statistics',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  // ── Scanning ───────────────────────────────────────────────────────────────

  @override
  Future<Result<List<String>>> scanOrphanTempFiles({
    Duration olderThan = const Duration(hours: 1),
  }) async {
    try {
      final config = await _requireConfig();
      final orphans = await scanner.scanOrphanTempFiles(
        tempDir: config.tempPath,
        olderThan: olderThan,
      );
      return Success(orphans);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Orphan scan failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<List<String>>> scanMissingConvertedFiles(
      List<String> knownPaths) async {
    try {
      final missing = await scanner.scanMissingFiles(knownPaths);
      return Success(missing);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Missing-file scan failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<List<String>>> scanLocalDocuments({required String appDocPath}) async {
    try {
      final docs = await scanner.scanLocalDocuments(appDocPath: appDocPath);
      return Success(docs);
    } catch (e, stack) {
      return FailureResult(StorageFailure(
        message: 'Local documents scan failed',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<StoragePathConfig> _requireConfig() async {
    if (_config != null) return _config!;
    final result = await ensureDirectories();
    if (result.isFailure) throw Exception(result.failure.message);
    return result.value;
  }
}
