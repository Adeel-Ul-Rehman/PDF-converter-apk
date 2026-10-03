import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flux_convert/core/services/storage_service.dart';
import 'package:flux_convert/features/storage/presentation/storage_manager.dart';

class LocalDocumentsState {
  const LocalDocumentsState({
    this.allFiles = const [],
    this.filteredFiles = const [],
    this.favoritePaths = const {},
    this.isLoading = false,
    this.activeTab = 'All Files',
    this.searchQuery = '',
    this.activeSort = 'Newest First',
    this.selectedExtensionFilter = 'All',
  });

  final List<File> allFiles;
  final List<File> filteredFiles;
  final Set<String> favoritePaths;
  final bool isLoading;
  final String activeTab;
  final String searchQuery;
  final String activeSort;
  final String selectedExtensionFilter;

  LocalDocumentsState copyWith({
    List<File>? allFiles,
    List<File>? filteredFiles,
    Set<String>? favoritePaths,
    bool? isLoading,
    String? activeTab,
    String? searchQuery,
    String? activeSort,
    String? selectedExtensionFilter,
  }) => LocalDocumentsState(
      allFiles: allFiles ?? this.allFiles,
      filteredFiles: filteredFiles ?? this.filteredFiles,
      favoritePaths: favoritePaths ?? this.favoritePaths,
      isLoading: isLoading ?? this.isLoading,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      activeSort: activeSort ?? this.activeSort,
      selectedExtensionFilter: selectedExtensionFilter ?? this.selectedExtensionFilter,
    );
}

class LocalDocumentsNotifier extends StateNotifier<LocalDocumentsState> {
  LocalDocumentsNotifier(this._storageManager, this._prefs) : super(const LocalDocumentsState()) {
    _loadFavorites();
    scanDocuments();
  }

  final StorageManager _storageManager;
  final SharedPreferences _prefs;

  static const _favsKey = 'flux_convert_favorite_docs';

  void _loadFavorites() {
    final list = _prefs.getStringList(_favsKey) ?? [];
    state = state.copyWith(favoritePaths: list.toSet());
  }

  Future<void> _saveFavorites(Set<String> favs) async {
    await _prefs.setStringList(_favsKey, favs.toList());
  }

  Future<void> scanDocuments() async {
    state = state.copyWith(isLoading: true);
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final result = await _storageManager.scanLocalDocuments(appDocDir.path);

      if (result.isSuccess) {
        final files = result.value.map(File.new).toList();
        state = state.copyWith(
          allFiles: files,
          isLoading: false,
        );
        _applyFiltersAndSort();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setTab(String tab) {
    state = state.copyWith(activeTab: tab);
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFiltersAndSort();
  }

  void setSort(String sort) {
    state = state.copyWith(activeSort: sort);
    _applyFiltersAndSort();
  }

  void setExtensionFilter(String ext) {
    state = state.copyWith(selectedExtensionFilter: ext);
    _applyFiltersAndSort();
  }

  Future<void> toggleFavorite(String path) async {
    final updated = Set<String>.from(state.favoritePaths);
    if (updated.contains(path)) {
      updated.remove(path);
    } else {
      updated.add(path);
    }
    state = state.copyWith(favoritePaths: updated);
    await _saveFavorites(updated);
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    var list = List<File>.from(state.allFiles);

    // Pre-cache stats to avoid O(N log N) synchronous filesystem stats calls during comparison
    final statsMap = <String, FileStat>{};
    for (final f in list) {
      try {
        statsMap[f.path] = f.statSync();
      } catch (_) {}
    }

    // 1. Tab Filtering
    if (state.activeTab == 'Favorites') {
      list = list.where((f) => state.favoritePaths.contains(f.path)).toList();
    } else if (state.activeTab == 'Recent') {
      // Show files modified in last 7 days
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      list = list.where((f) {
        final mod = statsMap[f.path]?.modified;
        return mod != null && mod.isAfter(cutoff);
      }).toList();
    }

    // 2. Extension Chip Filtering
    if (state.selectedExtensionFilter != 'All') {
      final extTarget = state.selectedExtensionFilter.toLowerCase();
      list = list.where((f) {
        final ext = f.path.split('.').last.toLowerCase();
        if (extTarget == 'word') return ext == 'doc' || ext == 'docx';
        if (extTarget == 'excel') return ext == 'xls' || ext == 'xlsx' || ext == 'csv' || ext == 'ods';
        if (extTarget == 'ppt') return ext == 'ppt' || ext == 'pptx';
        if (extTarget == 'images') return ['jpg','jpeg','png','webp','heic','bmp','gif','tiff'].contains(ext);
        if (extTarget == 'text') return ext == 'txt' || ext == 'rtf';
        return ext == extTarget;
      }).toList();
    }

    // 3. Search Matching
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      list = list.where((f) {
        final name = f.path.split('/').last.split(r'\').last.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    // 3. Sorting
    switch (state.activeSort) {
      case 'Newest First':
        list.sort((a, b) {
          final aMod = statsMap[a.path]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bMod = statsMap[b.path]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bMod.compareTo(aMod);
        });
      case 'Oldest First':
        list.sort((a, b) {
          final aMod = statsMap[a.path]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bMod = statsMap[b.path]?.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aMod.compareTo(bMod);
        });
      case 'Largest File':
        list.sort((a, b) {
          final aSize = statsMap[a.path]?.size ?? 0;
          final bSize = statsMap[b.path]?.size ?? 0;
          return bSize.compareTo(aSize);
        });
      case 'Smallest File':
        list.sort((a, b) {
          final aSize = statsMap[a.path]?.size ?? 0;
          final bSize = statsMap[b.path]?.size ?? 0;
          return aSize.compareTo(bSize);
        });
      case 'Alphabetical':
        list.sort((a, b) {
          final aName = a.path.split('/').last.split(r'\').last.toLowerCase();
          final bName = b.path.split('/').last.split(r'\').last.toLowerCase();
          return aName.compareTo(bName);
        });
    }

    state = state.copyWith(filteredFiles: list);
  }
}

final localDocumentsProvider = StateNotifierProvider<LocalDocumentsNotifier, LocalDocumentsState>((ref) {
  final storageManager = ref.watch(storageManagerProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalDocumentsNotifier(storageManager, prefs);
});
