import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';
import 'package:flux_convert/features/settings/presentation/providers/settings_providers.dart';

/// Presentation controller exposing typed actions for the settings UI.
class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  SettingsEntity get settings => _ref.read(settingsNotifierProvider);

  Future<void> load() =>
      _ref.read(settingsNotifierProvider.notifier).loadSettings();

  Future<void> updateTheme(String value) =>
      _ref.read(settingsNotifierProvider.notifier).updateTheme(value);

  Future<void> setBool({required String key, required bool value}) => _ref
      .read(settingsNotifierProvider.notifier)
      .setBoolSetting(key: key, value: value);

  Future<void> setInt({required String key, required int value}) => _ref
      .read(settingsNotifierProvider.notifier)
      .setIntSetting(key: key, value: value);

  Future<void> setString({required String key, required String value}) => _ref
      .read(settingsNotifierProvider.notifier)
      .setStringSetting(key: key, value: value);

  Future<void> reset() =>
      _ref.read(settingsNotifierProvider.notifier).resetSettings();
}

final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);
