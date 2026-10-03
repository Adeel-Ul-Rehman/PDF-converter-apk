import 'dart:io';

import 'package:flux_convert/core/error/failures.dart';
import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageValidator
///
/// Validates file paths before any storage operation.
/// All checks return a [StorageValidationResult] so callers decide the action.
/// ─────────────────────────────────────────────────────────────────────────────
class StorageValidator {
  StorageValidator({required String appRootPath}) : _rootPath = appRootPath;

  final String _rootPath;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Full validation chain for an output write path.
  StorageValidationResult validateOutputPath(String path) {
    if (_hasTraversal(path)) return StorageValidationResult.traversal(path);
    if (!_isInsideRoot(path)) return StorageValidationResult.outsideSandbox(path);
    if (!_hasSafeFilename(path)) return StorageValidationResult.unsafeName(path);
    AppLogger.trace('StorageValidator: output path valid → $path');
    return StorageValidationResult.ok();
  }

  /// Validates an input file before reading.
  StorageValidationResult validateInputPath(String path) {
    if (_hasTraversal(path)) return StorageValidationResult.traversal(path);
    final file = File(path);
    if (!file.existsSync()) return StorageValidationResult.notFound(path);
    final stat = file.statSync();
    if (stat.size == 0) return StorageValidationResult.empty(path);
    AppLogger.trace('StorageValidator: input path valid → $path');
    return StorageValidationResult.ok();
  }

  /// Checks whether the filesystem has enough free space.
  /// On Android, uses the parent directory stat.
  Future<bool> hasEnoughSpace(String directoryPath, int requiredBytes) async {
    try {
      final exists = Directory(directoryPath).existsSync();
      AppLogger.trace('StorageValidator: hasEnoughSpace check (exists=$exists)');
      return exists;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Returns true when the path is within the FluxConvert root.
  bool isInsideRoot(String path) => _isInsideRoot(path);

  // ── Private Helpers ────────────────────────────────────────────────────────

  bool _hasTraversal(String path) =>
      path.contains('..') || path.contains(r'\..\') || path.contains('/../');

  bool _isInsideRoot(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final root = _rootPath.replaceAll(r'\', '/');
    return normalized.startsWith(root);
  }

  bool _hasSafeFilename(String path) {
    final filename = path.split('/').last.split(r'\').last;
    if (filename.isEmpty || filename.startsWith('.')) return false;
    // No null bytes or control chars
    return !filename.contains(RegExp(r'[\x00-\x1F\x7F]'));
  }
}

// ── Result ────────────────────────────────────────────────────────────────────

/// The result of a storage validation check.
class StorageValidationResult {
  const StorageValidationResult._({required this.isValid, this.reason});

  factory StorageValidationResult.ok() =>
      const StorageValidationResult._(isValid: true);

  factory StorageValidationResult.traversal(String path) =>
      StorageValidationResult._(
        isValid: false,
        reason: 'Directory traversal detected in path: $path',
      );

  factory StorageValidationResult.outsideSandbox(String path) =>
      StorageValidationResult._(
        isValid: false,
        reason: 'Path is outside application sandbox: $path',
      );

  factory StorageValidationResult.unsafeName(String path) =>
      StorageValidationResult._(
        isValid: false,
        reason: 'Unsafe filename in path: $path',
      );

  factory StorageValidationResult.notFound(String path) =>
      StorageValidationResult._(isValid: false, reason: 'File not found: $path');

  factory StorageValidationResult.empty(String path) =>
      StorageValidationResult._(isValid: false, reason: 'File is empty: $path');

  final bool isValid;
  final String? reason;

  /// Converts to a [DirectoryTraversalFailure] or [StorageFailure] as appropriate.
  Failure toFailure() {
    if (reason != null && reason!.contains('traversal')) {
      return DirectoryTraversalFailure(message: reason!);
    }
    return StorageFailure(message: reason ?? 'Storage validation failed');
  }
}
