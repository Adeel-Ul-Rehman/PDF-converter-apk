import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// TemporaryFileProtector — Secures temporary workspaces for conversions.
///
/// Ensures temporary files have unguessable names, handles lifecycle tracking,
/// and securely wipes remnants.
/// ─────────────────────────────────────────────────────────────────────────────
class TemporaryFileProtector {
  TemporaryFileProtector(this._tempDirectoryPath);

  final String _tempDirectoryPath;
  final _uuid = const Uuid();

  /// Creates a secure temporary workspace file path.
  /// The file is NOT created on disk yet, but the path is guaranteed to be unique
  /// and within the application's temporary directory.
  Future<Result<String>> allocateSecureTempPath({required String extension}) async {
    try {
      final dir = Directory(_tempDirectoryPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Generate a crypto-strong random UUID for the temp filename
      final uniqueName = _uuid.v4().replaceAll('-', '');
      final cleanExt = extension.trim().replaceAll('.', '');
      
      final tempPath = p.join(_tempDirectoryPath, '${uniqueName}_sec.$cleanExt');
      
      return Success(tempPath);
    } catch (e, stack) {
      return FailureResult(UnknownSecurityFailure(
        message: 'Failed to allocate secure temporary workspace.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  /// Securely deletes a temporary file, ensuring it's wiped from the workspace.
  Future<Result<void>> releaseTempPath(String path) async {
    try {
      final file = File(path);
      
      // Ensure we are only deleting from the temp directory (anti-traversal check)
      final canonicalTemp = p.canonicalize(_tempDirectoryPath);
      final canonicalFile = p.canonicalize(path);

      if (!p.isWithin(canonicalTemp, canonicalFile)) {
        return const FailureResult(SecurityViolationFailure(
          message: 'Attempted to delete a file outside the secure temporary workspace.',
        ));
      }

      if (file.existsSync()) {
        await file.delete();
        AppLogger.info('Security: Released temporary workspace file -> $path');
      }
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownSecurityFailure(
        message: 'Failed to release secure temporary workspace.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  /// Cleans all files within the secure temp workspace.
  Future<Result<void>> wipeWorkspace() async {
    try {
      final dir = Directory(_tempDirectoryPath);
      if (dir.existsSync()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
             try {
                entity.deleteSync();
             } catch (e) {
                AppLogger.warning('Security: Failed to wipe temp file -> ${entity.path}');
             }
          }
        }
      }
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownSecurityFailure(
        message: 'Failed to wipe temporary workspace.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }
}
