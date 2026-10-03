import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/domain/entities/security_configuration.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SecurityRepository — Main business contract for safety and validations.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class SecurityRepository {
  /// Runs the full validation pipeline for an input file path and output requirements.
  Future<Result<void>> runFullPipeline({
    required String inputPath,
    required String targetExtension,
    required SecurityConfiguration config,
  });

  /// Performs checks on the file existence, signature, mime type, etc.
  Future<Result<void>> validateFile(String path, SecurityConfiguration config);

  /// Performs safety check on filepath (traversal, traversal checks, hidden file checks).
  Future<Result<void>> validatePath(String path, SecurityConfiguration config);

  /// Validates write capability and projected disk usage limit constraints.
  Future<Result<void>> validateStorage(String directoryPath, int requiredBytes);
}
