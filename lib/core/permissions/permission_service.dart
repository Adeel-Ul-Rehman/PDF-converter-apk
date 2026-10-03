import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PermissionService — Android Permission Management
///
/// Handles runtime permission requests for Android (including 13+ media permissions).
/// Provides checking, requesting, and status querying with graceful logging.
/// ─────────────────────────────────────────────────────────────────────────────
class PermissionService {
  const PermissionService();

  /// Checks if the given permission is granted.
  Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    AppLogger.trace('PermissionService: $permission status is $status');
    return status.isGranted;
  }

  /// Request a single permission, returning if it is granted after request.
  Future<PermissionStatus> request(Permission permission) async {
    AppLogger.info('PermissionService: Requesting $permission');
    final status = await permission.request();
    AppLogger.info('PermissionService: $permission request result: $status');
    return status;
  }

  /// Handles requesting Android storage / media permissions (Android 13+ aware).
  ///
  /// On Android 13 (API 33) and above, granular permissions for photos/videos
  /// must be requested instead of the legacy `storage` permission.
  Future<bool> requestStorageAndMediaPermission() async {
    // Determine the permissions needed based on platform version/SDK.
    // The permission_handler package handles SDK check under the hood for
    // Permission.photos and Permission.videos.
    
    // We check Permission.photos first as it covers media access on API 33+.
    // On older APIs, checking photos/videos/audio fallback to legacy storage.
    final photosGranted = await request(Permission.photos).then((s) => s.isGranted);
    
    if (photosGranted) {
      return true;
    }

    // Secondary fallback to storage just in case (older Android versions)
    final storageGranted = await request(Permission.storage).then((s) => s.isGranted);
    return storageGranted;
  }

  /// Handles requesting Android camera permission for Smart Scan.
  Future<PermissionStatus> requestCameraPermission() async {
    return request(Permission.camera);
  }

  /// Checks if camera permission is currently granted.
  Future<bool> isCameraGranted() async {
    return isGranted(Permission.camera);
  }

  /// Opens the Android system settings page for this app, so the user can
  /// manually grant permissions if they previously permanently denied them.
  Future<bool> openAppSettingsPage() async {
    AppLogger.warning('PermissionService: Opening App Settings Page');
    return openAppSettings();
  }
}

/// Provider for [PermissionService].
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionService(),
);
