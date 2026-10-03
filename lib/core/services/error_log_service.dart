import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flux_convert/core/logging/logger_service.dart';

/// Severity level of logged errors
enum ErrorSeverity {
  /// Red: Uncaught crashes, fatal exceptions
  crash,
  /// Orange: File, Network, State warnings
  warning,
  /// Yellow: Performance issues (>2s), UI thread freezes (>200ms)
  performance,
  /// Blue: Informational breadcrumbs
  info,
}

/// Category of logged events
enum ErrorCategory {
  crash,
  freeze,
  performance,
  network,
  file,
  memory,
  navigation,
  state,
}

/// A structured error log entry
class ErrorLogEntry {
  const ErrorLogEntry({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.category,
    required this.message,
    this.stackTrace = '',
    this.screenName = 'Unknown',
    this.lastUserActions = const [],
    this.deviceModel = 'Android Device',
    this.osVersion = 'Android',
    this.appVersion = '1.0.0+1',
    this.durationMs,
  });

  final String id;
  final String timestamp;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final String message;
  final String stackTrace;
  final String screenName;
  final List<String> lastUserActions;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final int? durationMs;

  // ignore: sort_constructors_first
  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) => ErrorLogEntry(
        id: json['id'] as String? ?? const Uuid().v4(),
        timestamp: json['timestamp'] as String? ?? '',
        severity: ErrorSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => ErrorSeverity.warning,
        ),
        category: ErrorCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ErrorCategory.state,
        ),
        message: json['message'] as String? ?? '',
        stackTrace: json['stackTrace'] as String? ?? '',
        screenName: json['screenName'] as String? ?? 'Unknown',
        lastUserActions: (json['lastUserActions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        deviceModel: json['deviceModel'] as String? ?? 'Android Device',
        osVersion: json['osVersion'] as String? ?? 'Android',
        appVersion: json['appVersion'] as String? ?? '1.0.0+1',
        durationMs: json['durationMs'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'severity': severity.name,
        'category': category.name,
        'message': message,
        'stackTrace': stackTrace,
        'screenName': screenName,
        'lastUserActions': lastUserActions,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'durationMs': durationMs,
      };
}

// IMPROVED: Production-Grade Centralized Error Log & Performance Monitoring Service
/// Centralized singleton service capturing all crashes, freezes, performance delays,
/// file/network failures, and UI user action breadcrumbs.
class ErrorLogService with WidgetsBindingObserver {
  ErrorLogService._();
  static final ErrorLogService instance = ErrorLogService._();

  static const String _storageKey = 'production_error_logs_v1';
  static const int _maxLogLimit = 100;

  final List<ErrorLogEntry> _logBuffer = [];
  final List<String> _userBreadcrumbs = [];
  String _currentScreen = 'Home';
  SharedPreferences? _prefs;

  /// Stream controller for live UI updates in Settings Error Viewer
  final StreamController<List<ErrorLogEntry>> _logStreamController =
      StreamController<List<ErrorLogEntry>>.broadcast();

  Stream<List<ErrorLogEntry>> get logStream => _logStreamController.stream;
  List<ErrorLogEntry> get currentLogs => List.unmodifiable(_logBuffer);

  /// Initializes error logger & loads persisted log buffer
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    WidgetsBinding.instance.addObserver(this);
    await _loadLogsFromStorage();
  }

  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
    recordUserAction('Navigated to $screenName');
  }

  /// Records a user action breadcrumb (stores last 3 actions)
  void recordUserAction(String action) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    if (_userBreadcrumbs.length >= 3) {
      _userBreadcrumbs.removeAt(0);
    }
    _userBreadcrumbs.add('[$timestamp] $action');
  }

  /// Core method to capture and buffer an error entry
  void recordError({
    required String message,
    required ErrorCategory category,
    required ErrorSeverity severity,
    Object? error,
    StackTrace? stackTrace,
    int? durationMs,
  }) {
    final now = DateTime.now();
    final timestamp =
        '${now.toIso8601String().replaceAll('T', ' ').substring(0, 19)}.${now.millisecond.toString().padLeft(3, '0')}';

    final entry = ErrorLogEntry(
      id: const Uuid().v4(),
      timestamp: timestamp,
      severity: severity,
      category: category,
      message: message + (error != null ? '\nDetails: $error' : ''),
      stackTrace: stackTrace?.toString() ?? '',
      screenName: _currentScreen,
      lastUserActions: List<String>.from(_userBreadcrumbs),
      durationMs: durationMs,
    );

    if (_logBuffer.length >= _maxLogLimit) {
      _logBuffer.removeAt(0);
    }
    _logBuffer.add(entry);

    _logStreamController.add(List.unmodifiable(_logBuffer));
    _saveLogsToStorage();

    // Mirror to debug logger
    AppLogger.error(message, error, stackTrace);
  }

  /// Measures operation runtime and logs warnings if > 2 seconds
  Future<T> trackPerformance<T>({
    required String operationName,
    required Future<T> Function() operation,
    int warningThresholdMs = 2000,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds >= warningThresholdMs) {
        recordError(
          message: 'Slow operation detected: "$operationName" took ${stopwatch.elapsedMilliseconds}ms',
          category: ErrorCategory.performance,
          severity: ErrorSeverity.performance,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }
      return result;
    } catch (e, stack) {
      stopwatch.stop();
      recordError(
        message: 'Operation "$operationName" failed after ${stopwatch.elapsedMilliseconds}ms',
        category: ErrorCategory.file,
        severity: ErrorSeverity.warning,
        error: e,
        stackTrace: stack,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  /// IMPROVED: Convenience wrapper for tracking CPU-heavy async operations.
  ///
  /// Auto-logs as [ErrorCategory.performance] when [work] takes longer than
  /// [thresholdMs] (default 2000ms). Designed for use around compute() calls.
  ///
  /// Usage:
  ///   final bytes = await ErrorLogService.instance.trackHeavyOp(
  ///     'PDF annotation export',
  ///     () => PdfAnnotationExporter().exportAnnotations(...),
  ///   );
  Future<T> trackHeavyOp<T>(
    String label,
    Future<T> Function() work, {
    int thresholdMs = 2000,
  }) =>
      trackPerformance(
        operationName: label,
        operation: work,
        warningThresholdMs: thresholdMs,
      );

  // ─── Framework Exception Hooks ──────────────────────────────────────────

  void onFlutterError(FlutterErrorDetails details) {
    recordError(
      message: 'Uncaught Flutter Exception: ${details.exceptionAsString()}',
      category: ErrorCategory.crash,
      severity: ErrorSeverity.crash,
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  bool onPlatformError(Object error, StackTrace stack) {
    recordError(
      message: 'Uncaught Platform/Isolate Exception: $error',
      category: ErrorCategory.crash,
      severity: ErrorSeverity.crash,
      error: error,
      stackTrace: stack,
    );
    return true; // Suppress native crash dialog in release
  }

  void onZoneError(Object error, StackTrace stack) {
    recordError(
      message: 'Uncaught Async Zone Error: $error',
      category: ErrorCategory.crash,
      severity: ErrorSeverity.crash,
      error: error,
      stackTrace: stack,
    );
  }

  @override
  void didHaveMemoryPressure() {
    recordError(
      message: 'System Memory Pressure Warning: Low memory detected on device',
      category: ErrorCategory.memory,
      severity: ErrorSeverity.warning,
    );
  }

  // ─── Storage & Export ───────────────────────────────────────────────────

  Future<void> _loadLogsFromStorage() async {
    try {
      final raw = _prefs?.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final jsonList = jsonDecode(raw) as List<dynamic>;
        _logBuffer.clear();
        for (final item in jsonList) {
          _logBuffer.add(ErrorLogEntry.fromJson(item as Map<String, dynamic>));
        }
        _logStreamController.add(List.unmodifiable(_logBuffer));
      }
    } catch (_) {}
  }

  Future<void> _saveLogsToStorage() async {
    try {
      final jsonList = _logBuffer.map((e) => e.toJson()).toList();
      await _prefs?.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Exports formatted log entries as a text file for sharing
  Future<File> exportLogsToFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/flux_convert_error_logs_${DateTime.now().millisecondsSinceEpoch}.txt');

    final sb = StringBuffer()
      ..writeln('=====================================================')
      ..writeln('FLUXCONVERT SYSTEM DIAGNOSTIC ERROR LOGS')
      ..writeln('Exported At: ${DateTime.now().toIso8601String()}')
      ..writeln('Total Log Entries: ${_logBuffer.length}')
      ..writeln('=====================================================\n');

    for (final entry in _logBuffer.reversed) {
      sb.writeln('[${entry.timestamp}] [${entry.severity.name.toUpperCase()}] [Category: ${entry.category.name.toUpperCase()}]');
      sb.writeln('Screen: ${entry.screenName}');
      if (entry.durationMs != null) {
        sb.writeln('Duration: ${entry.durationMs}ms');
      }
      sb.writeln('Message: ${entry.message}');
      if (entry.lastUserActions.isNotEmpty) {
        sb.writeln('User Action Breadcrumbs:');
        for (final b in entry.lastUserActions) {
          sb.writeln('  - $b');
        }
      }
      if (entry.stackTrace.isNotEmpty) {
        sb.writeln('Stack Trace:\n${entry.stackTrace}');
      }
      sb.writeln('-----------------------------------------------------\n');
    }

    await file.writeAsString(sb.toString());
    return file;
  }

  /// Clears all buffered and stored error logs
  Future<void> clearLogs() async {
    _logBuffer.clear();
    await _prefs?.remove(_storageKey);
    _logStreamController.add(const []);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logStreamController.close();
  }
}
