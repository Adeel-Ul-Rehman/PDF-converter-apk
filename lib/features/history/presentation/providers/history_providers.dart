import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/services/storage_service.dart';
import 'package:flux_convert/features/history/data/datasources/history_local_datasource.dart';
import 'package:flux_convert/features/history/data/repositories/history_repository_impl.dart';
import 'package:flux_convert/features/history/domain/entities/history_record.dart';
import 'package:flux_convert/features/history/domain/repositories/history_repository.dart';
import 'package:flux_convert/features/history/domain/usecases/clear_history_usecase.dart';
import 'package:flux_convert/features/history/domain/usecases/get_history_usecase.dart';
import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';
import 'package:flux_convert/features/history/domain/usecases/delete_history_usecase.dart';
import 'package:flux_convert/features/history/domain/usecases/filter_history_usecase.dart';
import 'package:flux_convert/features/history/domain/usecases/get_history_statistics_usecase.dart';
import 'package:flux_convert/features/history/domain/usecases/save_conversion_usecase.dart';
import 'package:flux_convert/features/history/domain/usecases/search_history_usecase.dart';
import 'package:flux_convert/features/storage/presentation/storage_manager.dart';
import 'package:flux_convert/features/history/data/models/conversion_history_model.dart';

/// Provides [HistoryLocalDataSource].
final historyLocalDataSourceProvider = Provider<HistoryLocalDataSource>(
  (ref) => HistoryLocalDataSourceImpl(ref.watch(sharedPreferencesProvider)),
);

/// Provides [HistoryRepository].
final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepositoryImpl(ref.watch(historyLocalDataSourceProvider)),
);

/// Provides [GetHistoryUseCase].
final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>(
  (ref) => GetHistoryUseCase(ref.watch(historyRepositoryProvider)),
);

/// Provides [ClearHistoryUseCase].
final clearHistoryUseCaseProvider = Provider<ClearHistoryUseCase>(
  (ref) => ClearHistoryUseCase(ref.watch(historyRepositoryProvider)),
);

// ── Rich Usecase Providers ───────────────────────────────────────────────────
final saveConversionUseCaseProvider = Provider<SaveConversionUseCase>(
  (ref) => SaveConversionUseCase(ref.watch(historyRepositoryProvider)),
);

final searchHistoryUseCaseProvider = Provider<SearchHistoryUseCase>(
  (ref) => SearchHistoryUseCase(ref.watch(historyRepositoryProvider)),
);

final deleteHistoryUseCaseProvider = Provider<DeleteHistoryUseCase>(
  (ref) => DeleteHistoryUseCase(ref.watch(historyRepositoryProvider)),
);

final filterHistoryUseCaseProvider = Provider<FilterHistoryUseCase>(
  (ref) => FilterHistoryUseCase(ref.watch(historyRepositoryProvider)),
);

final getHistoryStatisticsUseCaseProvider = Provider<GetHistoryStatisticsUseCase>(
  (ref) => GetHistoryStatisticsUseCase(ref.watch(historyRepositoryProvider)),
);

// ── Legacy Compatibility Notifier & State ─────────────────────────────────────
class HistoryState {
  const HistoryState({
    required this.records,
    required this.isLoading,
  });

  final List<HistoryRecord> records;
  final bool isLoading;

  HistoryState copyWith({
    List<HistoryRecord>? records,
    bool? isLoading,
  }) => HistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
    );
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier(
    this._getHistoryUseCase,
    this._clearHistoryUseCase,
  ) : super(const HistoryState(records: [], isLoading: false)) {
    loadHistory();
  }

  final GetHistoryUseCase _getHistoryUseCase;
  final ClearHistoryUseCase _clearHistoryUseCase;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    final result = await _getHistoryUseCase();
    if (result.isSuccess) {
      state = state.copyWith(
        records: result.value,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> clearHistory() async {
    state = state.copyWith(isLoading: true);
    final result = await _clearHistoryUseCase();
    if (result.isSuccess) {
      state = state.copyWith(
        records: [],
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
}

final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(
    ref.watch(getHistoryUseCaseProvider),
    ref.watch(clearHistoryUseCaseProvider),
  ),
);

// ── Rich Conversion History Notifier & State ───────────────────────────────
class RichHistoryState {
  const RichHistoryState({
    required this.historyList,
    required this.isLoading,
    required this.isSearching,
    required this.searchQuery,
    required this.stats,
    this.activeFilter,
    this.activeStatusFilter,
    this.activeDaysLimit,
    this.errorMessage,
  });

  final List<ConversionHistory> historyList;
  final bool isLoading;
  final bool isSearching;
  final String searchQuery;
  final Map<String, dynamic> stats;
  final String? activeFilter; // "documents", "images"
  final String? activeStatusFilter; // "completed", "failed", "cancelled"
  final int? activeDaysLimit; // 1, 7, 30
  final String? errorMessage;

  RichHistoryState copyWith({
    List<ConversionHistory>? historyList,
    bool? isLoading,
    bool? isSearching,
    String? searchQuery,
    Map<String, dynamic>? stats,
    String? activeFilter,
    String? activeStatusFilter,
    int? activeDaysLimit,
    String? errorMessage,
  }) => RichHistoryState(
      historyList: historyList ?? this.historyList,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      stats: stats ?? this.stats,
      activeFilter: activeFilter ?? this.activeFilter,
      activeStatusFilter: activeStatusFilter ?? this.activeStatusFilter,
      activeDaysLimit: activeDaysLimit ?? this.activeDaysLimit,
      errorMessage: errorMessage ?? this.errorMessage,
    );
}

class RichHistoryNotifier extends StateNotifier<RichHistoryState> {
  RichHistoryNotifier(this._ref)
      : super(const RichHistoryState(
          historyList: [],
          isLoading: false,
          isSearching: false,
          searchQuery: '',
          stats: {},
        )) {
    loadAllHistory();
    refreshStats();
  }

  final Ref _ref;
  int _offset = 0;

  /// Loads paginated history items.
  Future<void> loadAllHistory({bool loadMore = false}) async {
    if (state.isLoading) return;

    if (!loadMore) {
      _offset = 0;
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    final repo = _ref.read(historyRepositoryProvider);
    final result = await repo.getAllHistory(offset: _offset);

    if (result.isSuccess) {
      final list = result.value;
      if (loadMore) {
        state = state.copyWith(
          historyList: [...state.historyList, ...list],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          historyList: list,
          isLoading: false,
        );
      }
      _offset += list.length;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure.message,
      );
    }
  }

  /// Instant filter searches.
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, isSearching: query.isNotEmpty);
    final searchUsecase = _ref.read(searchHistoryUseCaseProvider);
    final result = await searchUsecase(query);

    if (result.isSuccess) {
      state = state.copyWith(historyList: result.value);
    }
  }

  /// Apply tags filters.
  Future<void> applyFilters({
    String? formatGroup,
    String? status,
    int? daysLimit,
  }) async {
    state = state.copyWith(
      isLoading: true,
      activeFilter: formatGroup,
      activeStatusFilter: status,
      activeDaysLimit: daysLimit,
    );

    final filterUsecase = _ref.read(filterHistoryUseCaseProvider);
    final result = await filterUsecase(
      formatGroup: formatGroup,
      status: status,
      daysLimit: daysLimit,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        historyList: result.value,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure.message,
      );
    }
  }

  /// Deletes a history item.
  Future<void> deleteItem(String id) async {
    final deleteUsecase = _ref.read(deleteHistoryUseCaseProvider);
    final result = await deleteUsecase.deleteSingle(id);

    if (result.isSuccess) {
      state = state.copyWith(
        historyList: state.historyList.where((item) => item.id != id).toList(),
      );
      refreshStats();
    }
  }

  /// Renames the destination file of a history item and updates the log.
  Future<bool> renameItem(String id, String newBaseName) async {
    final itemIndex = state.historyList.indexWhere((element) => element.id == id);
    if (itemIndex == -1) return false;

    final item = state.historyList[itemIndex];
    final storage = _ref.read(storageManagerProvider);

    final renameResult = await storage.renameFile(
      path: item.destinationFilePath,
      newBaseName: newBaseName,
    );

    if (renameResult.isSuccess) {
      final newPath = renameResult.value;
      final newName = newPath.split('/').last.split(r'\').last;

      final localDataSource = _ref.read(historyLocalDataSourceProvider);
      final rawList = await localDataSource.fetchHistory();
      final updatedRawList = rawList.map((m) {
        if (m.id == id) {
          return ConversionHistoryModel(
            id: m.id,
            conversionId: m.conversionId,
            sourceFileName: m.sourceFileName,
            sourceFilePath: m.sourceFilePath,
            destinationFileName: newName,
            destinationFilePath: newPath,
            sourceFormat: m.sourceFormat,
            destinationFormat: m.destinationFormat,
            originalFileSize: m.originalFileSize,
            convertedFileSize: m.convertedFileSize,
            conversionDurationMs: m.conversionDurationMs,
            conversionStatus: m.conversionStatus,
            createdDateEpoch: m.createdDateEpoch,
            completedDateEpoch: m.completedDateEpoch,
            errorMessage: m.errorMessage,
            thumbnailPath: m.thumbnailPath,
          );
        }
        return m;
      }).toList();
      await localDataSource.saveHistoryList(updatedRawList);

      final updatedStateList = state.historyList.map((element) {
        if (element.id == id) {
          return ConversionHistory(
            id: element.id,
            conversionId: element.conversionId,
            sourceFileName: element.sourceFileName,
            sourceFilePath: element.sourceFilePath,
            destinationFileName: newName,
            destinationFilePath: newPath,
            sourceFormat: element.sourceFormat,
            destinationFormat: element.destinationFormat,
            originalFileSize: element.originalFileSize,
            convertedFileSize: element.convertedFileSize,
            conversionDuration: element.conversionDuration,
            conversionStatus: element.conversionStatus,
            createdDate: element.createdDate,
            completedDate: element.completedDate,
            errorMessage: element.errorMessage,
            thumbnailPath: element.thumbnailPath,
          );
        }
        return element;
      }).toList();

      state = state.copyWith(historyList: updatedStateList);
      return true;
    }
    return false;
  }

  /// Deletes selection list.
  Future<void> deleteSelected(List<String> ids) async {
    final deleteUsecase = _ref.read(deleteHistoryUseCaseProvider);
    final result = await deleteUsecase.deleteMultiple(ids);

    if (result.isSuccess) {
      state = state.copyWith(
        historyList: state.historyList.where((item) => !ids.contains(item.id)).toList(),
      );
      refreshStats();
    }
  }

  /// Clears database history logs.
  Future<void> clearAllHistory() async {
    final clearUsecase = _ref.read(clearHistoryUseCaseProvider);
    final result = await clearUsecase();

    if (result.isSuccess) {
      state = state.copyWith(
        historyList: [],
        stats: {},
      );
      _offset = 0;
    }
  }

  /// Refreshes metrics statistics.
  Future<void> refreshStats() async {
    final statsUsecase = _ref.read(getHistoryStatisticsUseCaseProvider);
    final result = await statsUsecase();

    if (result.isSuccess) {
      state = state.copyWith(stats: result.value);
    }
  }
}

/// Provides the [RichHistoryNotifier] state.
final richHistoryNotifierProvider =
    StateNotifierProvider<RichHistoryNotifier, RichHistoryState>(RichHistoryNotifier.new);
