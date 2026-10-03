import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/history/domain/entities/history_record.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryRepository — Domain Repository Interface
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class HistoryRepository {
  /// Returns all history records, newest first. (compatibility fallback)
  Future<Result<List<HistoryRecord>>> getAllRecords();

  /// Saves a new [HistoryRecord] after a successful or failed conversion. (compatibility fallback)
  Future<Result<void>> saveRecord(HistoryRecord record);

  /// Deletes a single record by [id]. (compatibility fallback)
  Future<Result<void>> deleteRecord(String id);

  /// Clears the entire history log. (compatibility fallback)
  Future<Result<void>> clearAll();

  /// Saves a new [ConversionHistory] details record.
  Future<Result<void>> saveConversion(ConversionHistory history);

  /// Returns paginated history records list.
  Future<Result<List<ConversionHistory>>> getAllHistory({
    int limit = 50,
    int offset = 0,
  });

  /// Returns recent conversions list up to [limit].
  Future<Result<List<ConversionHistory>>> getRecentHistory(int limit);

  /// Instantly searches conversion records matching filenames/types.
  Future<Result<List<ConversionHistory>>> searchHistory(String query);

  /// Filters conversion records by category, status, and duration ranges.
  Future<Result<List<ConversionHistory>>> filterHistory({
    String? formatGroup, // "documents", "images"
    String? status, // "completed", "failed", "cancelled"
    int? daysLimit, // 1 (Today), 7, 30 days
  });

  /// Deletes a single history record.
  Future<Result<void>> deleteHistoryItem(String id);

  /// Deletes multiple history records.
  Future<Result<void>> deleteMultipleItems(List<String> ids);

  /// Clears all history records.
  Future<Result<void>> clearHistory();

  /// Aggregates database conversions statistics.
  Future<Result<Map<String, dynamic>>> getStatistics();
}
