import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_convert/core/services/error_log_service.dart';

// IMPROVED: Error log Riverpod state notifier
class ErrorLogState {
  const ErrorLogState({
    required this.logs,
    this.selectedCategory,
    this.searchQuery = '',
    this.isExporting = false,
  });

  final List<ErrorLogEntry> logs;
  final ErrorCategory? selectedCategory;
  final String searchQuery;
  final bool isExporting;

  List<ErrorLogEntry> get filteredLogs {
    return logs.where((entry) {
      if (selectedCategory != null && entry.category != selectedCategory) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchMsg = entry.message.toLowerCase().contains(q);
        final matchScreen = entry.screenName.toLowerCase().contains(q);
        final matchCategory = entry.category.name.toLowerCase().contains(q);
        return matchMsg || matchScreen || matchCategory;
      }
      return true;
    }).toList();
  }

  ErrorLogState copyWith({
    List<ErrorLogEntry>? logs,
    ErrorCategory? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    bool? isExporting,
  }) {
    return ErrorLogState(
      logs: logs ?? this.logs,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class ErrorLogNotifier extends StateNotifier<ErrorLogState> {
  ErrorLogNotifier() : super(ErrorLogState(logs: ErrorLogService.instance.currentLogs)) {
    _subscription = ErrorLogService.instance.logStream.listen((logs) {
      state = state.copyWith(logs: logs);
    });
  }

  late final StreamSubscription<List<ErrorLogEntry>> _subscription;

  void selectCategory(ErrorCategory? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<File> exportLogs() async {
    state = state.copyWith(isExporting: true);
    try {
      final file = await ErrorLogService.instance.exportLogsToFile();
      state = state.copyWith(isExporting: false);
      return file;
    } catch (_) {
      state = state.copyWith(isExporting: false);
      rethrow;
    }
  }

  Future<void> clearLogs() async {
    await ErrorLogService.instance.clearLogs();
    state = state.copyWith(logs: const []);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final errorLogNotifierProvider = StateNotifierProvider<ErrorLogNotifier, ErrorLogState>((ref) {
  return ErrorLogNotifier();
});
