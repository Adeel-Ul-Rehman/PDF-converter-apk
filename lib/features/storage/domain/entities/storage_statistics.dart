/// StorageStatistics — Aggregated Storage Usage Snapshot
class StorageStatistics {
  const StorageStatistics({
    required this.totalUsedBytes,
    required this.cacheBytes,
    required this.tempBytes,
    required this.historyBytes,
    required this.convertedFilesCount,
    required this.largestFilePath,
    required this.largestFileBytes,
    required this.oldestFilePath,
    required this.oldestFileDate,
    required this.newestFilePath,
    required this.newestFileDate,
  });

  final int totalUsedBytes;
  final int cacheBytes;
  final int tempBytes;
  final int historyBytes;
  final int convertedFilesCount;
  final String? largestFilePath;
  final int largestFileBytes;
  final String? oldestFilePath;
  final DateTime? oldestFileDate;
  final String? newestFilePath;
  final DateTime? newestFileDate;

  static const empty = StorageStatistics(
    totalUsedBytes: 0,
    cacheBytes: 0,
    tempBytes: 0,
    historyBytes: 0,
    convertedFilesCount: 0,
    largestFilePath: null,
    largestFileBytes: 0,
    oldestFilePath: null,
    oldestFileDate: null,
    newestFilePath: null,
    newestFileDate: null,
  );
}
