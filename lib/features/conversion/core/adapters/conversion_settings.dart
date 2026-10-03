/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionSettings
///
/// User configurations applied to conversion pipelines (e.g. compressions, qualities).
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionSettings {
  const ConversionSettings({
    this.compressionLevel = 0.5,
    this.imageQuality = 80,
    this.overwriteExisting = false,
    this.keepMetadata = true,
    this.generateUniqueName = true,
    this.outputFolder,
    this.customParameters = const {},
  });

  /// Default fallbacks for clean instantiations.
  static const defaultSettings = ConversionSettings();

  /// Target compression scaling from 0.0 (no compression) to 1.0 (max compression).
  final double compressionLevel;

  /// Compression quality factor for images from 0 to 100.
  final int imageQuality;

  /// Overwrite files on path collision instead of renaming.
  final bool overwriteExisting;

  /// Retain EXIF or file author properties in target outputs.
  final bool keepMetadata;

  /// Appends counters (e.g., file_1.pdf) to resolve path conflicts.
  final bool generateUniqueName;

  /// Target directory folder path. If null, defaults to app sandbox.
  final String? outputFolder;

  /// Extensible custom settings map for specific package adapter arguments.
  final Map<String, dynamic> customParameters;
}
