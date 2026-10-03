import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';

/// Repository contract for persisted settings.
abstract interface class SettingsRepository {
  Future<Result<SettingsEntity>> getSettings();
  Future<Result<void>> saveSettings(SettingsEntity settings);
  Future<Result<void>> resetSettings();
  Future<Result<void>> updateSetting(String key, Object? value);
  Future<Result<void>> clearPreferences();
}
