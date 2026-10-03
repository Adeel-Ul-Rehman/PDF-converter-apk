import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SettingsPreferences — Typed SharedPreferences wrapper for settings.
///
/// Provides typed read/write helpers for settings persistence without
/// exposing raw SharedPreferences to the repository layer. All settings
/// keys are centralised here to prevent duplication.
/// ─────────────────────────────────────────────────────────────────────────────
class SettingsPreferences {
  SettingsPreferences(this._prefs);

  /// Storage key for the serialised settings JSON payload.
  static const String settingsKey = 'fc_app_settings_v2';

  final SharedPreferences _prefs;

  /// Reads the raw settings JSON string, or `null` when absent.
  String? getSettingsJson() => _prefs.getString(settingsKey);

  /// Persists the settings JSON string.
  Future<bool> setSettingsJson(String json) =>
      _prefs.setString(settingsKey, json);

  /// Removes the stored settings payload.
  Future<bool> removeSettings() => _prefs.remove(settingsKey);

  /// Clears all preferences stored for this app.
  Future<bool> clearAll() => _prefs.clear();

  /// Returns `true` when a settings payload exists.
  bool hasSettings() => _prefs.containsKey(settingsKey);

  /// Reads a boolean preference.
  bool? getBool(String key) => _prefs.getBool(key);

  /// Reads an integer preference.
  int? getInt(String key) => _prefs.getInt(key);

  /// Reads a string preference.
  String? getString(String key) => _prefs.getString(key);

  /// Writes a boolean preference.
  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  /// Writes an integer preference.
  Future<bool> setInt(String key, {required int value}) =>
      _prefs.setInt(key, value);

  /// Writes a string preference.
  Future<bool> setString(String key, {required String value}) =>
      _prefs.setString(key, value);

  /// Removes an individual preference.
  Future<bool> remove(String key) => _prefs.remove(key);
}
