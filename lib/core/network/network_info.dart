import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// NetworkInfo — Connection Status Check
///
/// Interface to check network connectivity. Helpful for future Hybrid online
/// conversion operations.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class NetworkInfo {
  /// Returns true if connected to any network (WiFi, mobile, ethernet).
  Future<bool> get isConnected;

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// Concrete implementation of [NetworkInfo] using [Connectivity].
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    AppLogger.trace('NetworkInfo: Current connectivity check result: $result');
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}

/// Provider for [Connectivity] instance.
final connectivityProvider = Provider<Connectivity>(
  (ref) => Connectivity(),
);

/// Provider for [NetworkInfo] injection.
final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
);
