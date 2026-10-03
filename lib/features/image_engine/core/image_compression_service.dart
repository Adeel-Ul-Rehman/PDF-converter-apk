import 'package:flux_convert/features/image_engine/domain/entities/image_settings.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageCompressionService
///
/// Exposes quality and scale recalculation presets based on compression settings.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ImageCompressionService {
  /// Resolves the quality scale (0-100) and resize factors based on presets.
  static int resolveQuality(ImageCompressionPreset preset, int userQuality) => switch (preset) {
      ImageCompressionPreset.highQuality => 95,
      ImageCompressionPreset.balanced => 80,
      ImageCompressionPreset.smallSize => 55,
    };

  /// Calculates resizing scaling dimensions.
  static List<int> calculateResizedDimensions(
    int width,
    int height,
    ImageResizeParams resizeParams,
  ) {
    if (resizeParams.scale == ImageResizeScale.original) {
      return [width, height];
    }

    if (resizeParams.scale == ImageResizeScale.custom) {
      final targetW = resizeParams.customWidth ?? width;
      final targetH = resizeParams.customHeight ?? height;
      return [targetW, targetH];
    }

    final scaleFactor = switch (resizeParams.scale) {
      ImageResizeScale.scale25 => 0.25,
      ImageResizeScale.scale50 => 0.50,
      ImageResizeScale.scale75 => 0.75,
      _ => 1.0,
    };

    return [
      (width * scaleFactor).round(),
      (height * scaleFactor).round(),
    ];
  }
}
