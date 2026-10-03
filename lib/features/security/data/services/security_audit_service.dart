import 'package:flutter/foundation.dart';
import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SecurityAuditService — Logs lifecycle transitions and security events safely.
///
/// Ensures no sensitive data (absolute paths, passwords) leaks to logs.
/// ─────────────────────────────────────────────────────────────────────────────
class SecurityAuditService {
  /// Logs a security operation outcome (only in debug builds).
  static void logEvent(String operation, {String? safeDetail}) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final logMessage = '[$timestamp] SECURITY AUDIT: $operation'
        '${safeDetail != null ? ' | Detail: $safeDetail' : ''}';
    
    AppLogger.info(logMessage);
  }

  /// Logs a security violation or validation rejection.
  static void logViolation(String reason, {String? maskedPath}) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toUtc().toIso8601String();
    // In debug mode we can print masked paths, but never full paths of user documents.
    final logMessage = '[$timestamp] SECURITY VIOLATION: $reason'
        '${maskedPath != null ? ' | Target: $maskedPath' : ''}';

    AppLogger.warning(logMessage);
  }
}
