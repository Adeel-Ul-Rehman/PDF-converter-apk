import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionHistory — Rich Domain Entity
///
/// Holds metadata statistics, formats, durations, and status for history items.
/// ─────────────────────────────────────────────────────────────────────────────
final class ConversionHistory extends Equatable {
  const ConversionHistory({
    required this.id,
    required this.conversionId,
    required this.sourceFileName,
    required this.sourceFilePath,
    required this.destinationFileName,
    required this.destinationFilePath,
    required this.sourceFormat,
    required this.destinationFormat,
    required this.originalFileSize,
    required this.convertedFileSize,
    required this.conversionDuration,
    required this.conversionStatus,
    required this.createdDate,
    required this.completedDate,
    this.errorMessage,
    this.thumbnailPath,
  });

  final String id;
  final String conversionId;
  final String sourceFileName;
  final String sourceFilePath;
  final String destinationFileName;
  final String destinationFilePath;
  final String sourceFormat;
  final String destinationFormat;
  final int originalFileSize;
  final int convertedFileSize;
  final Duration conversionDuration;
  final String conversionStatus; // "completed", "failed", "cancelled"
  final DateTime createdDate;
  final DateTime completedDate;
  final String? errorMessage;
  final String? thumbnailPath;

  @override
  List<Object?> get props => [
        id,
        conversionId,
        sourceFileName,
        sourceFilePath,
        destinationFileName,
        destinationFilePath,
        sourceFormat,
        destinationFormat,
        originalFileSize,
        convertedFileSize,
        conversionDuration,
        conversionStatus,
        createdDate,
        completedDate,
        errorMessage,
        thumbnailPath,
      ];
}
