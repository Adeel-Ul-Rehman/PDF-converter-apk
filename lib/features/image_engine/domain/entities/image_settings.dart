/// ─────────────────────────────────────────────────────────────────────────────
/// Image Settings Entities
///
/// User configurations and resize presets for the image processing pipeline.
/// ─────────────────────────────────────────────────────────────────────────────
library;

enum ImageResizeScale {
  original,
  scale25, // 25% of original dimensions
  scale50, // 50% of original dimensions
  scale75, // 75% of original dimensions
  custom;
}

/// Parameters for custom image resizes.
class ImageResizeParams {
  const ImageResizeParams({
    this.scale = ImageResizeScale.original,
    this.customWidth,
    this.customHeight,
    this.maintainAspectRatio = true,
  });

  final ImageResizeScale scale;
  final int? customWidth;
  final int? customHeight;
  final bool maintainAspectRatio;
}

enum ImageCompressionPreset {
  highQuality, // lossless or very low lossy compression
  balanced,
  smallSize; // high lossy compression
}

/// Configurations applied to image processing pipelines.
class ImageSettings {
  const ImageSettings({
    this.outputQuality = 80,
    this.compressionLevel = 0.5,
    this.resizeParams = const ImageResizeParams(),
    this.keepMetadata = true,
    this.autoRename = true,
    this.overwriteExisting = false,
    this.outputFolder,
  });

  final int outputQuality;
  final double compressionLevel;
  final ImageResizeParams resizeParams;
  final bool keepMetadata;
  final bool autoRename;
  final bool overwriteExisting;
  final String? outputFolder;
}
