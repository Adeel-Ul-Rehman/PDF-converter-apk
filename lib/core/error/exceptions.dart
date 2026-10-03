/// ─────────────────────────────────────────────────────────────────────────────
/// AppException Hierarchy — Typed Exception System
///
/// All thrown exceptions in the app must be one of these typed subclasses.
/// Raw [Exception] or [Error] objects must NEVER propagate to the domain layer.
///
/// Each exception carries:
///   - [message]          Human-readable description (may be shown in UI).
///   - [technicalMessage] Developer-facing details for logs.
///   - [errorCode]        Machine-readable identifier (e.g. 'STORAGE_FULL').
///   - [stackTrace]       Captured stack for crash reporting.
///
/// Flow:
///   Data Layer throws AppException subclass
///     → Repository catches, converts to Failure
///       → Domain / Presentation reacts to Failure
/// ─────────────────────────────────────────────────────────────────────────────
library;

/// Base exception for all application-level errors.
abstract base class AppException implements Exception {
  const AppException({
    required this.message,
    required this.technicalMessage,
    required this.errorCode,
    this.stackTrace,
  });

  /// Human-readable error message safe to display in UI.
  final String message;

  /// Developer-facing technical detail for logs and crash reports.
  final String technicalMessage;

  /// Machine-readable code for programmatic handling (e.g. `'STORAGE_001'`).
  final String errorCode;

  /// The captured stack trace at the point the exception was thrown.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'AppException[$errorCode]: $message | tech: $technicalMessage';
}

// ─────────────────────────────────────────────────────────────────────────────
// Concrete Exception Types
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a read/write operation on local storage fails.
final class StorageException extends AppException {
  const StorageException({
    required super.message,
    required super.technicalMessage,
    super.errorCode = 'STORAGE_001',
    super.stackTrace,
  });
}

/// Thrown when a file format conversion operation fails.
final class ConversionException extends AppException {
  const ConversionException({
    required super.message,
    required super.technicalMessage,
    super.errorCode = 'CONVERSION_001',
    super.stackTrace,
  });
}

/// Thrown when a file system operation fails (read, write, copy, delete).
final class FileException extends AppException {
  const FileException({
    required super.message,
    required super.technicalMessage,
    super.errorCode = 'FILE_001',
    super.stackTrace,
  });
}

/// Thrown when a required runtime permission is denied by the user or system.
final class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    required super.technicalMessage,
    super.errorCode = 'PERMISSION_001',
    super.stackTrace,
  });
}

/// Thrown when a network operation fails (reserved for Hybrid mode).
final class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required super.technicalMessage,
    super.errorCode = 'NETWORK_001',
    super.stackTrace,
  });
}

/// Catch-all for unexpected exceptions with no specific category.
final class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    required super.technicalMessage,
    super.errorCode = 'UNKNOWN_001',
    super.stackTrace,
  });

  /// Wraps any raw [Object] as an [UnknownException].
  factory UnknownException.from(Object error, [StackTrace? stack]) =>
      UnknownException(
        message: 'An unexpected error occurred. Please try again.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );
}
