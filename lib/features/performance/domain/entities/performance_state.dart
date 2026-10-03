import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PerformanceState — Models the current runtime metrics of the application.
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
class PerformanceState {
  const PerformanceState({
    this.memoryUsageMB = 0,
    this.cachedThumbnails = 0,
    this.activeIsolates = 0,
    this.startupDurationMs = 0.0,
    this.isLowMemory = false,
  });

  factory PerformanceState.fromJson(Map<String, dynamic> json) {
    return PerformanceState(
      memoryUsageMB: (json['memoryUsageMB'] as int?) ?? 0,
      cachedThumbnails: (json['cachedThumbnails'] as int?) ?? 0,
      activeIsolates: (json['activeIsolates'] as int?) ?? 0,
      startupDurationMs: (json['startupDurationMs'] as double?) ?? 0.0,
      isLowMemory: (json['isLowMemory'] as bool?) ?? false,
    );
  }

  final int memoryUsageMB;
  final int cachedThumbnails;
  final int activeIsolates;
  final double startupDurationMs;
  final bool isLowMemory;

  PerformanceState copyWith({
    int? memoryUsageMB,
    int? cachedThumbnails,
    int? activeIsolates,
    double? startupDurationMs,
    bool? isLowMemory,
  }) {
    return PerformanceState(
      memoryUsageMB: memoryUsageMB ?? this.memoryUsageMB,
      cachedThumbnails: cachedThumbnails ?? this.cachedThumbnails,
      activeIsolates: activeIsolates ?? this.activeIsolates,
      startupDurationMs: startupDurationMs ?? this.startupDurationMs,
      isLowMemory: isLowMemory ?? this.isLowMemory,
    );
  }

  Map<String, dynamic> toJson() => {
        'memoryUsageMB': memoryUsageMB,
        'cachedThumbnails': cachedThumbnails,
        'activeIsolates': activeIsolates,
        'startupDurationMs': startupDurationMs,
        'isLowMemory': isLowMemory,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceState &&
          runtimeType == other.runtimeType &&
          memoryUsageMB == other.memoryUsageMB &&
          cachedThumbnails == other.cachedThumbnails &&
          activeIsolates == other.activeIsolates &&
          startupDurationMs == other.startupDurationMs &&
          isLowMemory == other.isLowMemory;

  @override
  int get hashCode => Object.hash(
        memoryUsageMB,
        cachedThumbnails,
        activeIsolates,
        startupDurationMs,
        isLowMemory,
      );
}
