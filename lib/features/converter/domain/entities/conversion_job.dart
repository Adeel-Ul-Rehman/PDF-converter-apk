import 'package:equatable/equatable.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionJob — Domain Entity
///
/// Represents a single file conversion task. This is a pure domain object.
/// ─────────────────────────────────────────────────────────────────────────────
final class ConversionJob extends Equatable {
  const ConversionJob({
    required this.id,
    required this.inputFilePath,
    required this.outputFilePath,
    required this.inputFormat,
    required this.outputFormat,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.progressPercent = 0,
  });

  final String id;
  final String inputFilePath;
  final String outputFilePath;
  final String inputFormat;
  final String outputFormat;
  final ConversionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int progressPercent;

  ConversionJob copyWith({
    String? id,
    String? inputFilePath,
    String? outputFilePath,
    String? inputFormat,
    String? outputFormat,
    ConversionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    int? progressPercent,
  }) =>
      ConversionJob(
        id: id ?? this.id,
        inputFilePath: inputFilePath ?? this.inputFilePath,
        outputFilePath: outputFilePath ?? this.outputFilePath,
        inputFormat: inputFormat ?? this.inputFormat,
        outputFormat: outputFormat ?? this.outputFormat,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        errorMessage: errorMessage ?? this.errorMessage,
        progressPercent: progressPercent ?? this.progressPercent,
      );

  @override
  List<Object?> get props => [
        id,
        inputFilePath,
        outputFilePath,
        inputFormat,
        outputFormat,
        status,
        createdAt,
        completedAt,
        errorMessage,
        progressPercent,
      ];
}

/// Possible states of a [ConversionJob].
enum ConversionStatus {
  queued,
  converting,
  completed,
  failed,
  cancelled,
}
