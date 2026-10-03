import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/core/services/storage_service.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';
import 'package:flux_convert/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flux_convert/features/settings/data/mappers/conversion_settings_bridge.dart';
import 'package:flux_convert/features/settings/data/preferences/settings_preferences.dart';
import 'package:flux_convert/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';
import 'package:flux_convert/features/settings/domain/repositories/settings_repository.dart';
import 'package:flux_convert/features/settings/domain/usecases/clear_preferences_usecase.dart';
import 'package:flux_convert/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:flux_convert/features/settings/domain/usecases/reset_settings_usecase.dart';
import 'package:flux_convert/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:flux_convert/features/settings/domain/usecases/update_setting_usecase.dart';

/// Provides [SettingsPreferences].
final settingsPreferencesProvider = Provider<SettingsPreferences>(
  (ref) => SettingsPreferences(ref.watch(sharedPreferencesProvider)),
);

/// Provides [SettingsLocalDataSource].
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) =>
      SettingsLocalDataSourceImpl(ref.watch(settingsPreferencesProvider)),
);

/// Provides [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider)),
);

/// Provides [GetSettingsUseCase].
final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>(
  (ref) => GetSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

/// Provides [SaveSettingsUseCase].
final saveSettingsUseCaseProvider = Provider<SaveSettingsUseCase>(
  (ref) => SaveSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

/// Provides [ResetSettingsUseCase].
final resetSettingsUseCaseProvider = Provider<ResetSettingsUseCase>(
  (ref) => ResetSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);

/// Provides [UpdateSettingUseCase].
final updateSettingUseCaseProvider = Provider<UpdateSettingUseCase>(
  (ref) => UpdateSettingUseCase(ref.watch(settingsRepositoryProvider)),
);

/// Provides [ClearPreferencesUseCase].
final clearPreferencesUseCaseProvider = Provider<ClearPreferencesUseCase>(
  (ref) => ClearPreferencesUseCase(ref.watch(settingsRepositoryProvider)),
);

/// Controller-like state notifier for settings.
class SettingsNotifier extends StateNotifier<SettingsEntity> {
  SettingsNotifier(
    this._getSettingsUseCase,
    this._saveSettingsUseCase,
    this._updateSettingUseCase,
    this._resetSettingsUseCase,
    this._clearPreferencesUseCase,
  ) : super(SettingsEntityDefaults.instance) {
    unawaited(loadSettings());
  }

  final GetSettingsUseCase _getSettingsUseCase;
  final SaveSettingsUseCase _saveSettingsUseCase;
  final UpdateSettingUseCase _updateSettingUseCase;
  final ResetSettingsUseCase _resetSettingsUseCase;
  final ClearPreferencesUseCase _clearPreferencesUseCase;

  Future<void> loadSettings() async {
    final result = await _getSettingsUseCase();
    if (result.isSuccess) {
      state = result.value;
    }
  }

  Future<void> save(SettingsEntity settings) async {
    final result = await _saveSettingsUseCase(settings);
    if (result.isSuccess) {
      state = settings;
    }
  }

  Future<void> updateSetting(String key, Object? value) async {
    final result = await _updateSettingUseCase(
      UpdateSettingParams(key: key, value: value),
    );
    if (result.isSuccess) {
      await loadSettings();
    }
  }

  Future<void> resetSettings() async {
    final result = await _resetSettingsUseCase();
    if (result.isSuccess) {
      await loadSettings();
    }
  }

  Future<void> clearPreferences() async {
    final result = await _clearPreferencesUseCase();
    if (result.isSuccess) {
      await loadSettings();
    }
  }

  Future<void> updateTheme(String themeMode) async {
    await updateSetting('themeMode', themeMode);
  }

  Future<void> toggleSaveToGallery({required bool value}) async {
    await updateSetting('saveToGallery', value);
  }

  Future<void> toggleClearTemp({required bool value}) async {
    await updateSetting('clearTempOnExit', value);
  }

  Future<void> setBoolSetting({
    required String key,
    required bool value,
  }) async {
    await updateSetting(key, value);
  }

  Future<void> setIntSetting({required String key, required int value}) async {
    await updateSetting(key, value);
  }

  Future<void> setStringSetting({
    required String key,
    required String value,
  }) async {
    await updateSetting(key, value);
  }
}

/// Provides [SettingsNotifier].
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsEntity>(
      (ref) => SettingsNotifier(
        ref.watch(getSettingsUseCaseProvider),
        ref.watch(saveSettingsUseCaseProvider),
        ref.watch(updateSettingUseCaseProvider),
        ref.watch(resetSettingsUseCaseProvider),
        ref.watch(clearPreferencesUseCaseProvider),
      ),
    );

/// Provides the conversion settings derived from the app settings.
///
/// Any conversion pipeline that needs user preferences (compression level,
/// default quality, overwrite, etc.) should watch this provider.
final conversionSettingsProvider = Provider<ConversionSettings>(
  (ref) => ConversionSettingsBridge.fromAppSettings(
    ref.watch(settingsNotifierProvider),
  ),
);
