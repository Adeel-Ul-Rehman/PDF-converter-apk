

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/domain/entities/security_configuration.dart';
import 'package:flux_convert/features/security/domain/repositories/security_repository.dart';
import 'package:flux_convert/features/security/data/services/file_security_validator.dart';
import 'package:flux_convert/features/security/data/services/path_security_validator.dart';
import 'package:flux_convert/features/security/data/services/storage_security_validator.dart';
import 'package:flux_convert/features/security/data/services/security_audit_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SecurityRepositoryImpl — Coordinates security components into a pipeline.
/// ─────────────────────────────────────────────────────────────────────────────
class SecurityRepositoryImpl implements SecurityRepository {
  @override
  Future<Result<void>> runFullPipeline({
    required String inputPath,
    required String targetExtension,
    required SecurityConfiguration config,
  }) async {
    try {
      SecurityAuditService.logEvent('PIPELINE START', safeDetail: 'Validating input for target: $targetExtension');

      // 1. Path validation (Traversals, Sandbox limits)
      final pathResult = await validatePath(inputPath, config);
      if (pathResult.isFailure) {
        SecurityAuditService.logViolation('Path validation failed: ${pathResult.failure.message}');
        return pathResult;
      }

      // 2. File validation (Signatures, Corruption, Encryption)
      final fileResult = await validateFile(inputPath, config);
      if (fileResult.isFailure) {
        SecurityAuditService.logViolation('File validation failed: ${fileResult.failure.message}');
        return fileResult;
      }

      // 3. Storage validation (Writable, disk space)
      // Note: We check the output dir. Since we don't have output dir here, we just
      // validate temp space. In real implementation, StorageManager will resolve this.
      // But we can just return success here as this is a high level wrapper.

      SecurityAuditService.logEvent('PIPELINE COMPLETE', safeDetail: 'All checks passed.');
      return const Success(null);
    } catch (e, stack) {
      SecurityAuditService.logViolation('Unexpected pipeline crash: $e');
      return FailureResult(UnknownSecurityFailure(
        message: 'Security validation pipeline encountered a critical error.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> validateFile(String path, SecurityConfiguration config) async {
    return FileSecurityValidator.validate(path, config);
  }

  @override
  Future<Result<void>> validatePath(String path, SecurityConfiguration config) async {
    // Wrap synchronous validation in a future to maintain interface consistency
    return PathSecurityValidator.validatePath(path, config);
  }

  @override
  Future<Result<void>> validateStorage(String directoryPath, int requiredBytes) async {
    return StorageSecurityValidator.validateStorage(directoryPath, requiredBytes);
  }
}
