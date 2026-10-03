import 'dart:convert';

import 'package:flux_convert/core/error/exceptions.dart';
import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/settings/data/models/settings_model.dart';
import 'package:flux_convert/features/settings/data/preferences/settings_preferences.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';

/// Local data source responsible for persisting settings with SharedPreferences.
abstract interface class SettingsLocalDataSource {
  Future<SettingsModel> fetchSettings();
  Future<void> cacheSettings(SettingsModel model);
  Future<void> resetSettings();
  Future<void> updateSetting(String key, Object? value);
  Future<void> clearPreferences();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(this._preferences);

  final SettingsPreferences _preferences;

  @override
  Future<SettingsModel> fetchSettings() async {
    try {
      final raw = _preferences.getSettingsJson();
      if (raw == null || raw.isEmpty) {
        return SettingsModel.fromDomain(SettingsEntityDefaults.instance);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const StorageException(
          message: 'Stored settings were unreadable.',
          technicalMessage: 'Settings payload was not a JSON object.',
        );
      }
      return SettingsModel.fromJson(decoded);
    } catch (error, stack) {
      if (error is StorageException) {
        rethrow;
      }
      throw StorageException(
        message: 'Unable to read stored settings.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> cacheSettings(SettingsModel model) async {
    try {
      await _preferences.setSettingsJson(jsonEncode(model.toJson()));
    } catch (error, stack) {
      throw StorageException(
        message: 'Unable to save settings.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      await _preferences.removeSettings();
      AppLogger.info('SettingsLocalDataSource: reset settings');
    } catch (error, stack) {
      throw StorageException(
        message: 'Unable to reset settings.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> updateSetting(String key, Object? value) async {
    try {
      final current = await fetchSettings();
      final updated = _applySetting(current, key, value);
      await cacheSettings(updated);
    } catch (error, stack) {
      if (error is StorageException) {
        rethrow;
      }
      throw StorageException(
        message: 'Unable to update setting.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> clearPreferences() async {
    try {
      await _preferences.clearAll();
    } catch (error, stack) {
      throw StorageException(
        message: 'Unable to clear preferences.',
        technicalMessage: error.toString(),
        stackTrace: stack,
      );
    }
  }

  SettingsModel _applySetting(SettingsModel current, String key, Object? value) {
    switch (key) {
      case 'themeMode':
        return SettingsModel.fromDomain(current.toDomain().copyWith(themeMode: value as String?));
      case 'language':
        return SettingsModel.fromDomain(current.toDomain().copyWith(language: value as String?));
      case 'outputFolder':
        return SettingsModel.fromDomain(current.toDomain().copyWith(outputFolder: value as String?));
      case 'defaultImageQuality':
        return SettingsModel.fromDomain(current.toDomain().copyWith(defaultImageQuality: value as int?));
      case 'compressionLevel':
        return SettingsModel.fromDomain(current.toDomain().copyWith(compressionLevel: value as int?));
      case 'defaultPdfQuality':
        return SettingsModel.fromDomain(current.toDomain().copyWith(defaultPdfQuality: value as int?));
      case 'generateUniqueFilename':
        return SettingsModel.fromDomain(current.toDomain().copyWith(generateUniqueFilename: value as bool?));
      case 'overwriteExistingFiles':
        return SettingsModel.fromDomain(current.toDomain().copyWith(overwriteExistingFiles: value as bool?));
      case 'deleteTempFilesAutomatically':
        return SettingsModel.fromDomain(current.toDomain().copyWith(deleteTempFilesAutomatically: value as bool?));
      case 'autoCleanupCache':
        return SettingsModel.fromDomain(current.toDomain().copyWith(autoCleanupCache: value as bool?));
      case 'enableAnimations':
        return SettingsModel.fromDomain(current.toDomain().copyWith(enableAnimations: value as bool?));
      case 'enableHapticFeedback':
        return SettingsModel.fromDomain(current.toDomain().copyWith(enableHapticFeedback: value as bool?));
      case 'enableNotifications':
        return SettingsModel.fromDomain(current.toDomain().copyWith(enableNotifications: value as bool?));
      case 'developerMode':
        return SettingsModel.fromDomain(current.toDomain().copyWith(developerMode: value as bool?));
      case 'enableDebugLogs':
        return SettingsModel.fromDomain(current.toDomain().copyWith(enableDebugLogs: value as bool?));
      case 'futureAiIntegrationEnabled':
        return SettingsModel.fromDomain(current.toDomain().copyWith(futureAiIntegrationEnabled: value as bool?));
      case 'futureOcrEnabled':
        return SettingsModel.fromDomain(current.toDomain().copyWith(futureOcrEnabled: value as bool?));
      case 'futureCloudSyncEnabled':
        return SettingsModel.fromDomain(current.toDomain().copyWith(futureCloudSyncEnabled: value as bool?));
      case 'futureBackupEnabled':
        return SettingsModel.fromDomain(current.toDomain().copyWith(futureBackupEnabled: value as bool?));
      case 'saveToGallery':
        return SettingsModel.fromDomain(current.toDomain().copyWith(saveToGallery: value as bool?));
      case 'clearTempOnExit':
        return SettingsModel.fromDomain(current.toDomain().copyWith(clearTempOnExit: value as bool?));
      case 'reduceMotion':
        return SettingsModel.fromDomain(current.toDomain().copyWith(reduceMotion: value as bool?));
      case 'largeText':
        return SettingsModel.fromDomain(current.toDomain().copyWith(largeText: value as bool?));
      case 'keepMetadata':
        return SettingsModel.fromDomain(current.toDomain().copyWith(keepMetadata: value as bool?));
      case 'defaultOutputFormat':
        return SettingsModel.fromDomain(current.toDomain().copyWith(defaultOutputFormat: value as String?));
      case 'showConversionNotifications':
        return SettingsModel.fromDomain(current.toDomain().copyWith(showConversionNotifications: value as bool?));
      case 'defaultSortOrder':
        return SettingsModel.fromDomain(current.toDomain().copyWith(defaultSortOrder: value as String?));
      case 'defaultHistoryFilter':
        return SettingsModel.fromDomain(current.toDomain().copyWith(defaultHistoryFilter: value as String?));
      default:
        throw const StorageException(
          message: 'Unsupported setting key.',
          technicalMessage: 'The setting key is not recognised.',
        );
    }
  }
}
