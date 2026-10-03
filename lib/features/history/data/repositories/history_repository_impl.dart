import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/history/data/datasources/history_local_datasource.dart';
import 'package:flux_convert/features/history/data/models/history_record_model.dart';
import 'package:flux_convert/features/history/domain/entities/history_record.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/data/models/conversion_history_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryRepositoryImpl — Concrete Repository
/// ─────────────────────────────────────────────────────────────────────────────
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._localDataSource);

  final HistoryLocalDataSource _localDataSource;

  // ── Legacy Compatibility ───────────────────────────────────────────────────
  @override
  Future<Result<List<HistoryRecord>>> getAllRecords() async {
    try {
      final list = await _localDataSource.fetchRecords();
      return Success(list.map((m) => m.toDomain()).toList());
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  @override
  Future<Result<void>> saveRecord(HistoryRecord record) async {
    try {
      await _localDataSource.saveRecord(HistoryRecordModel.fromDomain(record));
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  @override
  Future<Result<void>> deleteRecord(String id) async {
    try {
      final records = await _localDataSource.fetchRecords();
      records.removeWhere((r) => r.id == id);
      await _localDataSource.clearAll();
      for (final r in records.reversed) {
        await _localDataSource.saveRecord(r);
      }
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _localDataSource.clearAll();
      await _localDataSource.clearRichHistory();
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  // ── Rich Conversion History Implementation ───────────────────────────────
  @override
  Future<Result<void>> saveConversion(ConversionHistory history) async {
    try {
      final model = ConversionHistoryModel.fromDomain(history);
      await _localDataSource.saveHistoryItem(model);
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to write history record to preferences storage.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ConversionHistory>>> getAllHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final list = await _localDataSource.fetchHistory();
      final domainList = list.map((m) => m.toDomain()).toList();
      
      // Perform safe bounds check for pagination
      if (offset >= domainList.length) {
        return const Success([]);
      }
      final end = (offset + limit) < domainList.length ? (offset + limit) : domainList.length;
      final paginated = domainList.sublist(offset, end);
      return Success(paginated);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to read conversion logs.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ConversionHistory>>> getRecentHistory(int limit) async => getAllHistory(limit: limit);

  @override
  Future<Result<List<ConversionHistory>>> searchHistory(String query) async {
    try {
      final list = await _localDataSource.fetchHistory();
      final normalizedQuery = query.toLowerCase().trim();

      if (normalizedQuery.isEmpty) {
        return Success(list.map((m) => m.toDomain()).toList());
      }

      final filtered = list.where((item) {
        final matchesName = item.sourceFileName.toLowerCase().contains(normalizedQuery) ||
            item.destinationFileName.toLowerCase().contains(normalizedQuery);
        final matchesFormat = item.sourceFormat.toLowerCase() == normalizedQuery ||
            item.destinationFormat.toLowerCase() == normalizedQuery;
        final matchesStatus = item.conversionStatus.toLowerCase() == normalizedQuery;
        return matchesName || matchesFormat || matchesStatus;
      }).map((m) => m.toDomain()).toList();

      return Success(filtered);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to search history records.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<List<ConversionHistory>>> filterHistory({
    String? formatGroup,
    String? status,
    int? daysLimit,
  }) async {
    try {
      final list = await _localDataSource.fetchHistory();
      var filtered = list.map((m) => m.toDomain()).toList();

      // 1. Group check
      if (formatGroup != null) {
        final cleanGroup = formatGroup.toLowerCase().trim();
        final documentExts = {'pdf', 'docx', 'doc', 'txt', 'rtf', 'html', 'odt'};
        final imageExts = {'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'tiff', 'svg'};

        filtered = filtered.where((item) {
          final ext = item.destinationFormat.toLowerCase().replaceAll('.', '');
          if (cleanGroup == 'documents') {
            return documentExts.contains(ext);
          } else if (cleanGroup == 'images') {
            return imageExts.contains(ext);
          }
          return true;
        }).toList();
      }

      // 2. Status check
      if (status != null) {
        final cleanStatus = status.toLowerCase().trim();
        filtered = filtered.where((item) => item.conversionStatus.toLowerCase() == cleanStatus).toList();
      }

      // 3. Date bounds check
      if (daysLimit != null) {
        final cutoff = DateTime.now().subtract(Duration(days: daysLimit));
        filtered = filtered.where((item) => item.createdDate.isAfter(cutoff)).toList();
      }

      return Success(filtered);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to filter history records.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteHistoryItem(String id) async {
    try {
      await _localDataSource.deleteHistoryItem(id);
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to delete history record.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteMultipleItems(List<String> ids) async {
    try {
      final list = await _localDataSource.fetchHistory();
      list.removeWhere((item) => ids.contains(item.id));
      await _localDataSource.saveHistoryList(list);
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to delete selected records.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearHistory() async {
    try {
      await _localDataSource.clearRichHistory();
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to clear rich history database.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getStatistics() async {
    try {
      final list = await _localDataSource.fetchHistory();
      final total = list.length;
      final successful = list.where((item) => item.conversionStatus == 'completed').length;
      final failed = list.where((item) => item.conversionStatus == 'failed').length;
      final cancelled = list.where((item) => item.conversionStatus == 'cancelled').length;

      var totalStorageUsed = 0;
      var totalDurationMs = 0;
      var processedFilesCount = 0;

      for (final item in list) {
        if (item.conversionStatus == 'completed') {
          totalStorageUsed += item.convertedFileSize;
          processedFilesCount++;
        }
        totalDurationMs += item.conversionDurationMs;
      }

      final avgDurationMs = total > 0 ? (totalDurationMs / total) : 0.0;

      return Success({
        'totalConversions': total,
        'successful': successful,
        'failed': failed,
        'cancelled': cancelled,
        'totalFilesProcessed': processedFilesCount,
        'totalStorageUsed': totalStorageUsed,
        'averageConversionTimeMs': avgDurationMs,
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'Failed to aggregate statistics metrics.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
