/// ─────────────────────────────────────────────────────────────────────────────
/// ImageMetadata
///
/// Immutable metadata containing properties of the parsed image file.
/// ─────────────────────────────────────────────────────────────────────────────
class ImageMetadata {
  const ImageMetadata({
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.format,
    required this.colorDepth,
    required this.hasTransparency,
    required this.orientation,
    required this.createdDate,
    required this.modifiedDate,
  });

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Dimension string (e.g. "1920x1080").
  String get resolution => '${width}x$height';

  /// File size in bytes.
  final int fileSizeBytes;

  /// Target format (e.g. "png", "jpg", "webp").
  final String format;

  /// Color depth bits per pixel (e.g. 24, 32).
  final int colorDepth;

  /// True if the image contains alpha transparency channels.
  final bool hasTransparency;

  /// Orientation details extracted from EXIF tags (e.g., "Normal", "Rotated 90").
  final String orientation;

  /// Creation date/time.
  final DateTime createdDate;

  /// Modified date/time.
  final DateTime modifiedDate;

  @override
  String toString() =>
      'ImageMetadata($format): size=$resolution, transparent=$hasTransparency';
}
/// Aspect ratio calculation helper.
abstract final class ImageAspectRatioUtils {
  static double getAspectRatio(int width, int height) =>
      height == 0 ? 1.0 : width / height;

  static String formatRatio(int width, int height) {
    if (height == 0) return '1:1';
    final val = width / height;
    if ((val - 1.777).abs() < 0.05) return '16:9';
    if ((val - 1.333).abs() < 0.05) return '4:3';
    if ((val - 1.5).abs() < 0.05) return '3:2';
    if ((val - 1.0).abs() < 0.05) return '1:1';
    return '${val.toStringAsFixed(2)}:1';
  }
}
