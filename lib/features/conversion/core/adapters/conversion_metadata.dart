/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionMetadata
///
/// Model holding parsed details of files, helping estimate output parameters.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionMetadata {
  const ConversionMetadata({
    this.pageCount,
    this.width,
    this.height,
    this.mimeType,
    this.isEncrypted = false,
    this.author,
    this.rawData = const {},
  });

  /// Page count (for PDF, Word, PowerPoint files).
  final int? pageCount;

  /// Width in pixels (for image files).
  final double? width;

  /// Height in pixels (for image files).
  final double? height;

  /// MIME type string.
  final String? mimeType;

  /// Password protection state.
  final bool isEncrypted;

  /// Original author string.
  final String? author;

  /// Extensible key-value metadata store.
  final Map<String, dynamic> rawData;
}
