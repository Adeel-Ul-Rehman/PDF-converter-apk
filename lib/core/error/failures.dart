/// ─────────────────────────────────────────────────────────────────────────────
/// Failure Hierarchy — Domain-Layer Error Representation
///
/// Repositories return [Failure] subclasses inside [Result] wrappers instead
/// of throwing exceptions. This keeps the domain layer pure and testable.
///
/// Mapping rule (data layer):
///   [StorageException]    → [StorageFailure]
///   [ConversionException] → [ConversionFailure]
///   [FileException]       → [FileFailure]
///   [PermissionException] → [PermissionFailure]
///   [NetworkException]    → [NetworkFailure]
///   anything else         → [UnknownFailure]
///
/// Usage in a repository:
/// ```dart
/// try {
///   final data = await dataSource.loadRecords();
///   return Success(data);
/// } on StorageException catch (e) {
///   return FailureResult(StorageFailure.fromException(e));
/// } catch (e, stack) {
///   return FailureResult(UnknownFailure.fromError(e, stack));
/// }
/// ```
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flux_convert/core/error/exceptions.dart';

/// Base sealed class for all domain failures.
///
/// Sealed so that every call site using a `switch` expression is
/// exhaustive — the compiler warns when new failure types are added.
sealed class Failure {
  const Failure({
    required this.message,
    required this.errorCode,
    this.technicalMessage,
    this.stackTrace,
  });

  /// Human-readable description safe to display in the UI.
  final String message;

  /// Machine-readable code for programmatic handling.
  final String errorCode;

  /// Developer-facing technical detail for logs. May be `null` in production.
  final String? technicalMessage;

  /// Stack trace captured at the failure origin.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'Failure[$errorCode]: $message | tech: $technicalMessage';
}

// ─────────────────────────────────────────────────────────────────────────────
// Concrete Failure Types
// ─────────────────────────────────────────────────────────────────────────────

/// Failure originating from a local storage operation.
final class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.errorCode = 'STORAGE_001',
    super.technicalMessage,
    super.stackTrace,
  });

  factory StorageFailure.fromException(StorageException e) => StorageFailure(
        message: e.message,
        errorCode: e.errorCode,
        technicalMessage: e.technicalMessage,
        stackTrace: e.stackTrace,
      );
}

/// Failure originating from a file format conversion operation.
final class ConversionFailure extends Failure {
  const ConversionFailure({
    required super.message,
    super.errorCode = 'CONVERSION_001',
    super.technicalMessage,
    super.stackTrace,
  });

  factory ConversionFailure.fromException(ConversionException e) =>
      ConversionFailure(
        message: e.message,
        errorCode: e.errorCode,
        technicalMessage: e.technicalMessage,
        stackTrace: e.stackTrace,
      );
}

/// Failure originating from a file system operation.
final class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    super.errorCode = 'FILE_001',
    super.technicalMessage,
    super.stackTrace,
  });

  factory FileFailure.fromException(FileException e) => FileFailure(
        message: e.message,
        errorCode: e.errorCode,
        technicalMessage: e.technicalMessage,
        stackTrace: e.stackTrace,
      );
}

/// Failure originating from a denied runtime permission.
final class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.errorCode = 'PERMISSION_001',
    super.technicalMessage,
    super.stackTrace,
  });

  factory PermissionFailure.fromException(PermissionException e) =>
      PermissionFailure(
        message: e.message,
        errorCode: e.errorCode,
        technicalMessage: e.technicalMessage,
        stackTrace: e.stackTrace,
      );
}

/// Failure originating from a network error (reserved for Hybrid mode).
final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.errorCode = 'NETWORK_001',
    super.technicalMessage,
    super.stackTrace,
  });

  factory NetworkFailure.fromException(NetworkException e) => NetworkFailure(
        message: e.message,
        errorCode: e.errorCode,
        technicalMessage: e.technicalMessage,
        stackTrace: e.stackTrace,
      );
}

/// Catch-all failure with no specific category.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.errorCode = 'UNKNOWN_001',
    super.technicalMessage,
    super.stackTrace,
  });

  factory UnknownFailure.fromError(Object error, [StackTrace? stack]) =>
      UnknownFailure(
        message: 'An unexpected error occurred. Please try again.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );

  factory UnknownFailure.fromException(AppException e) => UnknownFailure(
        message: e.message,
        errorCode: e.errorCode,
        technicalMessage: e.technicalMessage,
        stackTrace: e.stackTrace,
      );
}

/// Failure originating from a general conversion issue.
final class ConversionError extends Failure {
  const ConversionError({
    required super.message,
    super.errorCode = 'CONVERSION_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from a parameter validation issue.
final class ValidationError extends Failure {
  const ValidationError({
    required super.message,
    super.errorCode = 'VALIDATION_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from output path file generation.
final class OutputError extends Failure {
  const OutputError({
    required super.message,
    super.errorCode = 'OUTPUT_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from local storage constraints or space.
final class StorageError extends Failure {
  const StorageError({
    required super.message,
    super.errorCode = 'STORAGE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from queue execution blocks.
final class QueueError extends Failure {
  const QueueError({
    required super.message,
    super.errorCode = 'QUEUE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure wrapper for unhandled pipeline crashes.
final class UnknownConversionError extends Failure {
  const UnknownConversionError({
    required super.message,
    super.errorCode = 'UNKNOWN_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from an unsupported document format mapping.
final class UnsupportedDocumentFailure extends Failure {
  const UnsupportedDocumentFailure({
    required super.message,
    super.errorCode = 'DOC_UNSUPPORTED_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from password-locked or encrypted document files.
final class EncryptedDocumentFailure extends Failure {
  const EncryptedDocumentFailure({
    required super.message,
    super.errorCode = 'DOC_ENCRYPTED_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from corrupt headers or structure mismatch in document files.
final class CorruptedDocumentFailure extends Failure {
  const CorruptedDocumentFailure({
    required super.message,
    super.errorCode = 'DOC_CORRUPT_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from document files exceeding the 100 MB limits.
final class LargeDocumentFailure extends Failure {
  const LargeDocumentFailure({
    required super.message,
    super.errorCode = 'DOC_TOO_LARGE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from missing or deleted document source paths.
final class MissingDocumentFailure extends Failure {
  const MissingDocumentFailure({
    required super.message,
    super.errorCode = 'DOC_MISSING_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Catch-all document-specific pipeline failure.
final class UnknownDocumentFailure extends Failure {
  const UnknownDocumentFailure({
    required super.message,
    super.errorCode = 'DOC_UNKNOWN_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from an unsupported image format.
final class UnsupportedImageFailure extends Failure {
  const UnsupportedImageFailure({
    required super.message,
    super.errorCode = 'IMG_UNSUPPORTED_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from corruption in image file headers.
final class CorruptedImageFailure extends Failure {
  const CorruptedImageFailure({
    required super.message,
    super.errorCode = 'IMG_CORRUPT_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating when decoding/encoding sizes exceed the heap bounds.
final class MemoryLimitExceededFailure extends Failure {
  const MemoryLimitExceededFailure({
    required super.message,
    super.errorCode = 'IMG_OOM_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Catch-all image-specific pipeline failure.
final class UnknownImageFailure extends Failure {
  const UnknownImageFailure({
    required super.message,
    super.errorCode = 'IMG_UNKNOWN_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from database read/write faults.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.errorCode = 'DB_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating from JSON parsing or model mismatch.
final class CorruptedRecordFailure extends Failure {
  const CorruptedRecordFailure({
    required super.message,
    super.errorCode = 'RECORD_CORRUPT_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure originating when target outputs are deleted by users.
final class MissingFileFailure extends Failure {
  const MissingFileFailure({
    required super.message,
    super.errorCode = 'FILE_MISSING_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when the device has insufficient storage space.
final class DiskFullFailure extends Failure {
  const DiskFullFailure({
    required super.message,
    super.errorCode = 'DISK_FULL_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when a file is locked by another process.
final class LockedFileFailure extends Failure {
  const LockedFileFailure({
    required super.message,
    super.errorCode = 'LOCKED_FILE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when a path escapes the application sandbox (directory traversal attempt).
final class DirectoryTraversalFailure extends Failure {
  const DirectoryTraversalFailure({
    required super.message,
    super.errorCode = 'DIR_TRAVERSAL_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when a permission query is denied by user or OS.
final class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({
    required super.message,
    super.errorCode = 'PERMISSION_DENIED_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when path validation fails (unsafe chars, reserved names).
final class UnsafePathFailure extends Failure {
  const UnsafePathFailure({
    required super.message,
    super.errorCode = 'UNSAFE_PATH_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when file validation fails (empty file, duplicate file).
final class InvalidFileFailure extends Failure {
  const InvalidFileFailure({
    required super.message,
    super.errorCode = 'INVALID_FILE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when file corruption is detected.
final class CorruptedFileFailure extends Failure {
  const CorruptedFileFailure({
    required super.message,
    super.errorCode = 'CORRUPTED_FILE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when MIME type validation fails.
final class InvalidMimeFailure extends Failure {
  const InvalidMimeFailure({
    required super.message,
    super.errorCode = 'INVALID_MIME_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when file signature checks fail.
final class InvalidSignatureFailure extends Failure {
  const InvalidSignatureFailure({
    required super.message,
    super.errorCode = 'INVALID_SIGNATURE_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when storage boundaries are violated.
final class StorageViolationFailure extends Failure {
  const StorageViolationFailure({
    required super.message,
    super.errorCode = 'STORAGE_VIOLATION_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Failure when a general security constraint is violated.
final class SecurityViolationFailure extends Failure {
  const SecurityViolationFailure({
    required super.message,
    super.errorCode = 'SECURITY_VIOLATION_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}

/// Generic unknown security failure.
final class UnknownSecurityFailure extends Failure {
  const UnknownSecurityFailure({
    required super.message,
    super.errorCode = 'UNKNOWN_SECURITY_FAIL',
    super.technicalMessage,
    super.stackTrace,
  });
}
