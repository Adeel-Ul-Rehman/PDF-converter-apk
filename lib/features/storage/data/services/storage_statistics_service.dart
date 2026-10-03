import 'dart:io';
import 'dart:isolate';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageStatisticsService
///
/// Aggregates directory sizes without loading file bytes into memory.
/// Heavy computation runs inside an isolate.
/// ─────────────────────────────────────────────────────────────────────────────
class StorageStatisticsService {
  Future<StorageStatistics> compute({
    required String convertedDocumentsPath,
    required String convertedImagesPath,
    required String cachePath,
    required String tempPath,
    required String historyPath,
  }) async {
    AppLogger.info('StorageStatisticsService: beginning compute in isolate');

    final result = await Isolate.run(
      () => _compute(
        convertedDocumentsPath,
        convertedImagesPath,
        cachePath,
        tempPath,
        historyPath,
      ),
    );

    AppLogger.info('StorageStatisticsService: total=${result.totalUsedBytes} bytes');
    return result;
  }

  // ── Isolate entry point ────────────────────────────────────────────────────

  static StorageStatistics _compute(
    String docsDir,
    String imgsDir,
    String cacheDir,
    String tempDir,
    String historyDir,
  ) {
    final allConverted = [
      ..._listFiles(docsDir),
      ..._listFiles(imgsDir),
    ];
    final cacheFiles = _listFiles(cacheDir);
    final tempFiles = _listFiles(tempDir);
    final historyFiles = _listFiles(historyDir);

    var total = 0;
    var cacheBytes = 0;
    var tempBytes = 0;
    var historyBytes = 0;

    String? largestPath;
    var largestBytes = 0;
    String? oldestPath;
    DateTime? oldestDate;
    String? newestPath;
    DateTime? newestDate;

    void process(List<File> files, {bool isCounts = false}) {
      for (final f in files) {
        final stat = f.statSync();
        final size = stat.size;
        final mod = stat.modified;
        total += size;
        if (size > largestBytes) {
          largestBytes = size;
          largestPath = f.path;
        }
        if (oldestDate == null || mod.isBefore(oldestDate!)) {
          oldestDate = mod;
          oldestPath = f.path;
        }
        if (newestDate == null || mod.isAfter(newestDate!)) {
          newestDate = mod;
          newestPath = f.path;
        }
      }
    }

    process(allConverted);
    for (final f in cacheFiles) {
      cacheBytes += f.statSync().size;
      total += f.statSync().size;
    }
    for (final f in tempFiles) {
      tempBytes += f.statSync().size;
      total += f.statSync().size;
    }
    for (final f in historyFiles) {
      historyBytes += f.statSync().size;
      total += f.statSync().size;
    }

    return StorageStatistics(
      totalUsedBytes: total,
      cacheBytes: cacheBytes,
      tempBytes: tempBytes,
      historyBytes: historyBytes,
      convertedFilesCount: allConverted.length,
      largestFilePath: largestPath,
      largestFileBytes: largestBytes,
      oldestFilePath: oldestPath,
      oldestFileDate: oldestDate,
      newestFilePath: newestPath,
      newestFileDate: newestDate,
    );
  }

  static List<File> _listFiles(String dir) {
    final directory = Directory(dir);
    if (!directory.existsSync()) return const [];
    try {
      return directory
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
    } on Exception catch (_) {
      return const [];
    }
  }
}
