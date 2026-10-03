import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/network/network_info.dart';
import 'package:flux_convert/core/permissions/permission_service.dart';
import 'package:flux_convert/core/services/file_storage_service.dart';
import 'package:flux_convert/core/services/storage_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Dependency Injection Providers
///
/// Central hub containing Riverpod providers for all core infrastructure services.
/// Keeps application setup neat, visible, and easy to override in unit tests.
/// ─────────────────────────────────────────────────────────────────────────────

/// Core SharedPreferences key-value storage provider.
final coreStorageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(sharedPreferencesProvider)),
);

/// Core file storage provider.
final coreFileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => FileStorageService(),
);

/// Core permissions service provider.
final corePermissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionService(),
);

/// Core network connectivity status provider.
final coreNetworkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);
