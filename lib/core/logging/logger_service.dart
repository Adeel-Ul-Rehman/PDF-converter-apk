import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppLogger — Debug-aware Structured Logger
///
/// Wraps the [Logger] package with a singleton that is automatically silenced
/// in release builds. All logging calls are guard-checked via [kDebugMode]
/// so there is zero performance cost in release.
///
/// Usage:
/// ```dart
/// AppLogger.info('Something happened');
/// AppLogger.warning('This looks wrong', someError, stackTrace);
/// AppLogger.error('Critical failure', exception, stackTrace);
/// ```
/// ─────────────────────────────────────────────────────────────────────────────
final class AppLogger {
  const AppLogger._();

  static late final Logger _logger;
  static final List<String> _errorLogs = [];

  /// Exposes current buffered error logs
  static List<String> get errorLogs => List.unmodifiable(_errorLogs);

  /// Clears buffered error logs
  static void clearLogs() {
    _errorLogs.clear();
  }

  /// Initialises the logger. Must be called once before any log calls,
  /// typically at the top of [main].
  static void init() {
    _logger = Logger(
      filter: kReleaseMode ? _SilentFilter() : DevelopmentFilter(),
      printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.trace : Level.off,
    );
  }

  /// Logs a verbose/trace message. Use for fine-grained diagnostic output.
  static void trace(String message) {
    if (kDebugMode) _logger.t(message);
  }

  /// Logs a standard informational message.
  static void info(String message) {
    if (kDebugMode) _logger.i(message);
  }

  /// Logs a warning that may indicate an unexpected but non-fatal state.
  static void warning(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) _logger.w(message, error: error, stackTrace: stack);
  }

  /// Logs a non-fatal error with optional exception and stack trace.
  static void error(String message, [Object? error, StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    final logEntry = '[$timestamp] ERROR: $message'
        '${error != null ? '\nError: $error' : ''}'
        '${stack != null ? '\nStack:\n$stack' : ''}';
    
    if (_errorLogs.length >= 100) {
      _errorLogs.removeAt(0);
    }
    _errorLogs.add(logEntry);

    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stack);
    }
  }

  /// Logs a fatal error that likely means the app cannot continue.
  static void fatal(String message, [Object? error, StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
    final logEntry = '[$timestamp] FATAL: $message'
        '${error != null ? '\nError: $error' : ''}'
        '${stack != null ? '\nStack:\n$stack' : ''}';
    
    if (_errorLogs.length >= 100) {
      _errorLogs.removeAt(0);
    }
    _errorLogs.add(logEntry);

    if (kDebugMode) {
      _logger.f(message, error: error, stackTrace: stack);
    }
  }
}

/// A [LogFilter] implementation that suppresses all log output.
/// Applied automatically in release builds.
final class _SilentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}
