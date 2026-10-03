import 'package:flux_convert/core/logging/logger_service.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';
import 'package:flux_convert/features/settings/domain/entities/settings_entity.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionSettingsBridge — Maps AppSettings into ConversionSettings.
///
/// This is the single integration point that flows user preferences into the
/// conversion pipeline. No conversion call should hardcode these values;
/// they must always resolve through this bridge.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ConversionSettingsBridge {
  /// Builds a [ConversionSettings] from the given [SettingsEntity].
  static ConversionSettings fromAppSettings(SettingsEntity settings) {
    AppLogger.trace(
      'ConversionSettingsBridge: mapping settings to conversion config',
    );

    return ConversionSettings(
      compressionLevel: (settings.compressionLevel / 10).clamp(0.0, 1.0),
      imageQuality: settings.defaultImageQuality,
      overwriteExisting: settings.overwriteExistingFiles,
      keepMetadata: settings.keepMetadata,
      generateUniqueName: settings.generateUniqueFilename,
      outputFolder: settings.outputFolder.isEmpty
          ? null
          : settings.outputFolder,
    );
  }
}
