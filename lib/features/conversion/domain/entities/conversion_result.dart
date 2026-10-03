/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionResult
///
/// Output report returned upon successful execution of the conversion pipeline.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionResult {
  const ConversionResult({
    required this.sourcePath,
    required this.destinationPath,
    required this.fileSizeBytes,
    required this.duration,
    required this.outputName,
    required this.isSuccess,
    this.failureMessage,
  });

  /// Absolute file system path of the source input.
  final String sourcePath;

  /// Absolute file system path of the final converted output.
  final String destinationPath;

  /// Size of the resulting output file in bytes.
  final int fileSizeBytes;

  /// Duration taken to complete the parsing.
  final Duration duration;

  /// Resulting file name with extension.
  final String outputName;

  /// Flag indicating whether the conversion completed without error.
  final bool isSuccess;

  /// Failure error logs if isSuccess is false.
  final String? failureMessage;

  @override
  String toString() =>
      'ConversionResult: $outputName ($fileSizeBytes bytes) in ${duration.inMilliseconds}ms';
}
