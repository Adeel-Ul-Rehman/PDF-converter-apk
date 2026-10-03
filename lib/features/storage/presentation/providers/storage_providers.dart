import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/features/storage/data/repositories/storage_repository_impl.dart';
import 'package:flux_convert/features/storage/data/services/directory_manager.dart';
import 'package:flux_convert/features/storage/data/services/file_naming_service.dart';
import 'package:flux_convert/features/storage/data/services/storage_cleaner.dart';
import 'package:flux_convert/features/storage/data/services/storage_scanner.dart';
import 'package:flux_convert/features/storage/data/services/storage_statistics_service.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_path_config.dart';
import 'package:flux_convert/features/storage/domain/entities/storage_statistics.dart';
import 'package:flux_convert/features/storage/domain/repositories/storage_repository.dart';
import 'package:flux_convert/features/storage/domain/usecases/clean_cache_use_case.dart';
import 'package:flux_convert/features/storage/domain/usecases/clean_temp_use_case.dart';
import 'package:flux_convert/features/storage/domain/usecases/ensure_directories_use_case.dart';
import 'package:flux_convert/features/storage/domain/usecases/get_storage_statistics_use_case.dart';
import 'package:flux_convert/features/storage/domain/usecases/scan_orphans_use_case.dart';

// ── Service Providers ─────────────────────────────────────────────────────────

final directoryManagerProvider = Provider<DirectoryManager>(
  (_) => DirectoryManager(),
);

final fileNamingServiceProvider = Provider<FileNamingService>(
  (_) => FileNamingService(),
);

final storageScannerProvider = Provider<StorageScanner>(
  (_) => StorageScanner(),
);

final storageCleanerProvider = Provider<StorageCleaner>(
  (_) => StorageCleaner(),
);

final storageStatisticsServiceProvider = Provider<StorageStatisticsService>(
  (_) => StorageStatisticsService(),
);

// ── Repository Provider ───────────────────────────────────────────────────────

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepositoryImpl(
    directoryManager: ref.watch(directoryManagerProvider),
    namingService: ref.watch(fileNamingServiceProvider),
    scanner: ref.watch(storageScannerProvider),
    cleaner: ref.watch(storageCleanerProvider),
    statisticsService: ref.watch(storageStatisticsServiceProvider),
  ),
);

// ── Use Case Providers ────────────────────────────────────────────────────────

final ensureDirectoriesUseCaseProvider = Provider<EnsureDirectoriesUseCase>(
  (ref) => EnsureDirectoriesUseCase(ref.watch(storageRepositoryProvider)),
);

final cleanTempUseCaseProvider = Provider<CleanTempUseCase>(
  (ref) => CleanTempUseCase(ref.watch(storageRepositoryProvider)),
);

final cleanCacheUseCaseProvider = Provider<CleanCacheUseCase>(
  (ref) => CleanCacheUseCase(ref.watch(storageRepositoryProvider)),
);

final getStorageStatisticsUseCaseProvider = Provider<GetStorageStatisticsUseCase>(
  (ref) => GetStorageStatisticsUseCase(ref.watch(storageRepositoryProvider)),
);

final scanOrphansUseCaseProvider = Provider<ScanOrphansUseCase>(
  (ref) => ScanOrphansUseCase(ref.watch(storageRepositoryProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────────

enum StorageState { loading, scanning, cleaning, ready, deleting, error }

class StorageStatus {
  const StorageStatus({
    required this.state,
    this.pathConfig,
    this.statistics,
    this.orphanPaths = const [],
    this.errorMessage,
  });

  final StorageState state;
  final StoragePathConfig? pathConfig;
  final StorageStatistics? statistics;
  final List<String> orphanPaths;
  final String? errorMessage;

  bool get isReady => state == StorageState.ready;

  StorageStatus copyWith({
    StorageState? state,
    StoragePathConfig? pathConfig,
    StorageStatistics? statistics,
    List<String>? orphanPaths,
    String? errorMessage,
  }) =>
      StorageStatus(
        state: state ?? this.state,
        pathConfig: pathConfig ?? this.pathConfig,
        statistics: statistics ?? this.statistics,
        orphanPaths: orphanPaths ?? this.orphanPaths,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  static const initial = StorageStatus(state: StorageState.loading);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StorageNotifier extends StateNotifier<StorageStatus> {
  StorageNotifier(this._ref) : super(StorageStatus.initial);

  final Ref _ref;

  Future<void> initialise() async {
    state = StorageStatus.initial;
    final result = await _ref.read(ensureDirectoriesUseCaseProvider)();
    if (result.isSuccess) {
      state = StorageStatus(
        state: StorageState.ready,
        pathConfig: result.value,
      );
    } else {
      state = StorageStatus(
        state: StorageState.error,
        errorMessage: result.failure.message,
      );
    }
  }

  Future<void> refreshStatistics() async {
    final current = state;
    state = current.copyWith(state: StorageState.scanning);
    final result = await _ref.read(getStorageStatisticsUseCaseProvider)();
    if (result.isSuccess) {
      state = state.copyWith(
        state: StorageState.ready,
        statistics: result.value,
      );
    } else {
      state = current.copyWith(
        state: StorageState.error,
        errorMessage: result.failure.message,
      );
    }
  }

  Future<void> cleanTemp() async {
    state = state.copyWith(state: StorageState.cleaning);
    await _ref.read(cleanTempUseCaseProvider)();
    state = state.copyWith(state: StorageState.ready);
    await refreshStatistics();
  }

  Future<void> cleanCache() async {
    state = state.copyWith(state: StorageState.cleaning);
    await _ref.read(cleanCacheUseCaseProvider)();
    state = state.copyWith(state: StorageState.ready);
    await refreshStatistics();
  }

  Future<void> scanOrphans() async {
    state = state.copyWith(state: StorageState.scanning);
    final result = await _ref.read(scanOrphansUseCaseProvider)();
    if (result.isSuccess) {
      state = state.copyWith(
        state: StorageState.ready,
        orphanPaths: result.value,
      );
    } else {
      state = state.copyWith(
        state: StorageState.error,
        errorMessage: result.failure.message,
      );
    }
  }

  Future<void> deleteFile(String path) async {
    state = state.copyWith(state: StorageState.deleting);
    final repo = _ref.read(storageRepositoryProvider);
    await repo.deleteFile(path);
    state = state.copyWith(state: StorageState.ready);
    await refreshStatistics();
  }
}

final storageNotifierProvider =
    StateNotifierProvider<StorageNotifier, StorageStatus>(
  StorageNotifier.new,
);

final storagePathConfigProvider = Provider<StoragePathConfig?>(
  (ref) => ref.watch(storageNotifierProvider).pathConfig,
);

final storageStatisticsProvider = Provider<StorageStatistics?>(
  (ref) => ref.watch(storageNotifierProvider).statistics,
);
