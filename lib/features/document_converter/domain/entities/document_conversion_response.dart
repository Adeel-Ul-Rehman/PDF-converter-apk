/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionResponse
///
/// Output report returned upon successful execution of document conversions.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentConversionResponse {
  const DocumentConversionResponse({
    required this.outputPath,
    required this.fileSizeBytes,
    required this.duration,
  });

  /// Absolute file system path of the converted output document.
  final String outputPath;

  /// Converted file size in bytes.
  final int fileSizeBytes;

  /// Total duration taken to complete parsing.
  final Duration duration;

  @override
  String toString() =>
      'DocumentConversionResponse($outputPath): $fileSizeBytes bytes in ${duration.inMilliseconds}ms';
}
