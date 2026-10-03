import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/domain/entities/security_configuration.dart';
import 'package:flux_convert/features/security/domain/repositories/security_repository.dart';
import 'package:flux_convert/features/security/data/services/permission_manager.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SecurityManager — The central facade for security features.
/// ─────────────────────────────────────────────────────────────────────────────
class SecurityManager {
  SecurityManager({
    required this.repository,
    required this.permissionManager,
  });

  final SecurityRepository repository;
  final SecurityPermissionManager permissionManager;

  // The active security configuration policy.
  final SecurityConfiguration config = const SecurityConfiguration();

  /// Helper to run the pipeline, checking permissions first.
  Future<Result<void>> authorizeAndValidateConversion({
    required String inputPath,
    required String targetExtension,
  }) async {
    // 1. Request/Verify Storage permissions
    final permissionResult = await permissionManager.requestStorageAccess();
    if (permissionResult.isFailure) return permissionResult;

    // 2. Run the security file and path pipeline
    return repository.runFullPipeline(
      inputPath: inputPath,
      targetExtension: targetExtension,
      config: config,
    );
  }
}
