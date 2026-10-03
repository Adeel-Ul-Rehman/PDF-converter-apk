import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SecurityPermissionManager — Centralized interface for mapping OS permissions.
/// ─────────────────────────────────────────────────────────────────────────────
class SecurityPermissionManager {
  SecurityPermissionManager(this._permissionService);

  final PermissionService _permissionService;

  /// Requests storage and media access, mapped securely to domain failures.
  Future<Result<void>> requestStorageAccess() async {
    try {
      final isGranted = await _permissionService.requestStorageAndMediaPermission();
      
      if (!isGranted) {
        return const FailureResult(PermissionDeniedFailure(
          message: 'Storage permission was denied. The app cannot convert files without access.',
        ));
      }
      
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownSecurityFailure(
        message: 'Failed to request storage permission.',
        technicalMessage: e.toString(),
        stackTrace: stack,
      ));
    }
  }

  /// Opens application settings if permissions were permanently denied.
  Future<void> openSettings() async {
    await _permissionService.openAppSettingsPage();
  }
}
