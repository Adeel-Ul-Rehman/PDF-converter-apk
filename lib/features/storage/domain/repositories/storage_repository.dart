import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageRepository — Abstract Storage Contract
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class StorageRepository {
  Future<Result<StoragePathConfig>> ensureDirectories();
  Future<Result<String>> resolveOutputPath({required String baseName, required String extension});
  Future<Result<String>> resolveTempPath({required String extension});
  Future<Result<bool>> fileExists(String path);
  Future<Result<void>> deleteFile(String path);
  Future<Result<void>> deleteMultipleFiles(List<String> paths);
  Future<Result<String>> copyFile({required String sourcePath, required String destinationDir});
  Future<Result<String>> moveFile({required String sourcePath, required String destinationDir});
  Future<Result<String>> renameFile({required String path, required String newBaseName});
  Future<Result<String>> prepareShareUri(String path);
  Future<Result<void>> openFile(String path);
  Future<Result<bool>> validatePath(String path);
  Future<Result<void>> cleanCache();
  Future<Result<void>> cleanTemp();
  Future<Result<void>> cleanAll();
  Future<Result<StorageStatistics>> getStatistics();
  Future<Result<List<String>>> scanOrphanTempFiles({Duration olderThan = const Duration(hours: 1)});
  Future<Result<List<String>>> scanMissingConvertedFiles(List<String> knownPaths);
  Future<Result<List<String>>> scanLocalDocuments({required String appDocPath});
}
