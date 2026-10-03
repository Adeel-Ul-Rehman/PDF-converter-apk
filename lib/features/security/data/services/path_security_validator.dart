import 'package:path/path.dart' as p;
import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/domain/entities/security_configuration.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PathSecurityValidator — Guards against path traversal and malicious filenames.
///
/// Ensures all file access happens within allowed boundaries and filenames are safe.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class PathSecurityValidator {
  /// Known system reserved names (Windows) that should never be accessed.
  static const _reservedNames = {
    'con', 'prn', 'aux', 'nul',
    'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
    'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
  };

  /// Validates a path for traversal attacks, reserved names, and safety.
  static Result<void> validatePath(String path, SecurityConfiguration config) {
    try {
      if (path.isEmpty) {
        return const FailureResult(UnsafePathFailure(message: 'Path cannot be empty.'));
      }

      // ── 1. Canonicalization and Traversal Check ──────────────────────────────
      // p.canonicalize resolves '..' and '.' 
      final canonicalPath = p.canonicalize(path);
      
      // If the original path contained traversal markers that got resolved out,
      // it might be suspicious, but p.canonicalize handles it safely. 
      // However, we must ensure it doesn't escape our allowed roots.
      if (path.contains('..')) {
        return FailureResult(DirectoryTraversalFailure(
          message: 'Path contains directory traversal sequences.',
          technicalMessage: 'Detected ".." in path: $path',
        ));
      }

      // ── 2. Sandbox Boundary Check ────────────────────────────────────────────
      // Ensure the path is within one of the allowed directories (if configured).
      if (config.allowedDirectories.isNotEmpty) {
        var isAllowed = false;
        for (final allowedDir in config.allowedDirectories) {
          final canonicalAllowed = p.canonicalize(allowedDir);
          if (p.isWithin(canonicalAllowed, canonicalPath) || p.equals(canonicalAllowed, canonicalPath)) {
            isAllowed = true;
            break;
          }
        }
        
        if (!isAllowed) {
          return const FailureResult(StorageViolationFailure(
            message: 'Path is outside of application permitted directories.',
          ));
        }
      }

      // ── 3. Filename Safety Check ─────────────────────────────────────────────
      final basename = p.basename(canonicalPath);
      
      // Check for hidden files (starting with dot, except . and .. which are handled)
      if (basename.startsWith('.') && basename.length > 1) {
        return const FailureResult(UnsafePathFailure(
          message: 'Hidden files are not allowed.',
        ));
      }

      // Check reserved names
      final basenameWithoutExtension = p.basenameWithoutExtension(canonicalPath).toLowerCase();
      if (_reservedNames.contains(basenameWithoutExtension)) {
        return const FailureResult(UnsafePathFailure(
          message: 'Filename uses a reserved system name.',
        ));
      }
      
      // Check for unsafe characters (common illegal chars in Windows/Linux)
      // Allow alphanumeric, spaces, dashes, underscores, dots, parentheses
      final safeRegex = RegExp(r'^[a-zA-Z0-9_\-\.\ \(\)]+$');
      if (!safeRegex.hasMatch(basename)) {
         return const FailureResult(UnsafePathFailure(
          message: 'Filename contains unsafe or illegal characters.',
        ));
      }

      return const Success(null);
    } catch (e, stack) {
       return FailureResult(UnknownSecurityFailure(
          message: 'Path validation failed unexpectedly.',
          technicalMessage: e.toString(),
          stackTrace: stack,
       ));
    }
  }
}
