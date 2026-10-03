import 'package:flutter/foundation.dart';

import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/core/services/error_log_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Global Error Handler
///
/// Centralises all unhandled exception reporting for the app.
/// Integrates with [ErrorLogService] for production-grade diagnostic logging.
/// ─────────────────────────────────────────────────────────────────────────────
final class AppErrorHandler {
  const AppErrorHandler._();

  /// Handles errors thrown by the Flutter framework (e.g. widget build errors).
  static void onFlutterError(FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter Error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );

    ErrorLogService.instance.onFlutterError(details);
  }

  /// Handles errors thrown on the platform thread / Dart isolates.
  static bool onPlatformError(Object error, StackTrace stack) {
    AppLogger.error('Platform Error: $error', error, stack);
    return ErrorLogService.instance.onPlatformError(error, stack);
  }

  /// Catches uncaught async errors that escape the root Zone.
  static void onZoneError(Object error, StackTrace stack) {
    AppLogger.error('Zone Error: $error', error, stack);
    ErrorLogService.instance.onZoneError(error, stack);
  }
}
