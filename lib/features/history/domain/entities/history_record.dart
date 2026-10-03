import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryRecord — Domain Entity
///
/// Represents a completed (or failed) conversion entry in the history log.
/// ─────────────────────────────────────────────────────────────────────────────
final class HistoryRecord extends Equatable {
  const HistoryRecord({
    required this.id,
    required this.inputFileName,
    required this.outputFileName,
    required this.inputFormat,
    required this.outputFormat,
    required this.inputSizeBytes,
    required this.outputSizeBytes,
    required this.convertedAt,
    required this.wasSuccessful,
    this.outputFilePath,
  });

  final String id;
  final String inputFileName;
  final String outputFileName;
  final String inputFormat;
  final String outputFormat;
  final int inputSizeBytes;
  final int outputSizeBytes;
  final DateTime convertedAt;
  final bool wasSuccessful;

  /// Null if the output file has been deleted or conversion failed.
  final String? outputFilePath;

  @override
  List<Object?> get props => [
        id,
        inputFileName,
        outputFileName,
        inputFormat,
        outputFormat,
        inputSizeBytes,
        outputSizeBytes,
        convertedAt,
        wasSuccessful,
        outputFilePath,
      ];
}
