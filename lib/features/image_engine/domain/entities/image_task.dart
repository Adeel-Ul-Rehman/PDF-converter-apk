import 'package:flux_convert/features/image_engine/domain/entities/image_settings.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageTask
///
/// Entity representing an image conversion job configuration parameters.
/// ─────────────────────────────────────────────────────────────────────────────
class ImageTask {
  const ImageTask({
    required this.taskId,
    required this.sourcePath,
    required this.targetFormat, // png, jpg, jpeg, webp, bmp, gif, tiff, svg, heic, pdf
    required this.outputPath,
    this.settings = const ImageSettings(),
  });

  /// Unique task ID.
  final String taskId;

  /// Input source image file path.
  final String sourcePath;

  /// Target format extension string (lowercase, e.g. "png").
  final String targetFormat;

  /// Absolute target output file path.
  final String outputPath;

  /// Formatting settings (compressions, resizing, metadata).
  final ImageSettings settings;
}
