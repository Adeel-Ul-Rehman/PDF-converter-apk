import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flux_convert/core/logging/logger_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StorageService — Lightweight Key-Value Persistence
///
/// Wraps SharedPreferences to provide a typed, testable interface.
/// For file-based storage, use FileStorageService instead.
///
/// Injected via Riverpod: use [storageServiceProvider].
/// ─────────────────────────────────────────────────────────────────────────────
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  // ── Write ──────────────────────────────────────────────────────────────────
  Future<bool> setString(String key, String value) async {
    AppLogger.trace('StorageService: setString($key)');
    return _prefs.setString(key, value);
  }

  Future<bool> setBool(String key, {required bool value}) async {
    AppLogger.trace('StorageService: setBool($key, $value)');
    return _prefs.setBool(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    AppLogger.trace('StorageService: setInt($key, $value)');
    return _prefs.setInt(key, value);
  }

  // ── Read ───────────────────────────────────────────────────────────────────
  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<bool> remove(String key) async {
    AppLogger.trace('StorageService: remove($key)');
    return _prefs.remove(key);
  }

  Future<bool> clearAll() async {
    AppLogger.warning('StorageService: clearAll() called');
    return _prefs.clear();
  }

  bool containsKey(String key) => _prefs.containsKey(key);
}

// ── Providers ──────────────────────────────────────────────────────────────────

/// Provides SharedPreferences — must be overridden at ProviderScope root.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden before use.',
  ),
);

/// Provides the [StorageService] singleton.
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(sharedPreferencesProvider)),
);
