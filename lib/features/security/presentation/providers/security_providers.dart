import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/security/domain/repositories/security_repository.dart';
import 'package:flux_convert/features/security/data/repositories/security_repository_impl.dart';
import 'package:flux_convert/features/security/data/services/permission_manager.dart';
import 'package:flux_convert/features/security/data/services/security_manager.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Security Providers — Riverpod injection definitions.
/// ─────────────────────────────────────────────────────────────────────────────

/// Provides the core SecurityRepository.
final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepositoryImpl();
});

/// Provides the PermissionManager wrapper.
final securityPermissionManagerProvider = Provider<SecurityPermissionManager>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  return SecurityPermissionManager(permissionService);
});

/// Provides the central SecurityManager.
final securityManagerProvider = Provider<SecurityManager>((ref) {
  final repository = ref.watch(securityRepositoryProvider);
  final permissionManager = ref.watch(securityPermissionManagerProvider);

  return SecurityManager(
    repository: repository,
    permissionManager: permissionManager,
  );
});

/// ─────────────────────────────────────────────────────────────────────────────
/// Security State Management
/// ─────────────────────────────────────────────────────────────────────────────
enum SecurityValidationState {
  idle,
  checkingPermissions,
  validating,
  completed,
  failed,
}

class SecurityStateNotifier extends StateNotifier<SecurityValidationState> {
  SecurityStateNotifier() : super(SecurityValidationState.idle);

  // ignore: use_setters_to_change_properties
  void updateState(SecurityValidationState newState) {
    state = newState;
  }
}

/// Provider for UI to track real-time security validation progress if needed.
final securityStateProvider =
    StateNotifierProvider<SecurityStateNotifier, SecurityValidationState>((ref) {
  return SecurityStateNotifier();
});
