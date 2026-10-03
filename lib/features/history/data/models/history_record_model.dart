import 'package:flux_convert/features/history/domain/entities/history_record.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// HistoryRecordModel — Serialization model for history data
/// ─────────────────────────────────────────────────────────────────────────────
class HistoryRecordModel {
  const HistoryRecordModel({
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

  factory HistoryRecordModel.fromJson(Map<String, dynamic> json) => HistoryRecordModel(
      id: json['id'] as String,
      inputFileName: json['inputFileName'] as String,
      outputFileName: json['outputFileName'] as String,
      inputFormat: json['inputFormat'] as String,
      outputFormat: json['outputFormat'] as String,
      inputSizeBytes: json['inputSizeBytes'] as int,
      outputSizeBytes: json['outputSizeBytes'] as int,
      convertedAt: json['convertedAt'] as String,
      wasSuccessful: json['wasSuccessful'] as bool,
      outputFilePath: json['outputFilePath'] as String?,
    );

  factory HistoryRecordModel.fromDomain(HistoryRecord entity) => HistoryRecordModel(
      id: entity.id,
      inputFileName: entity.inputFileName,
      outputFileName: entity.outputFileName,
      inputFormat: entity.inputFormat,
      outputFormat: entity.outputFormat,
      inputSizeBytes: entity.inputSizeBytes,
      outputSizeBytes: entity.outputSizeBytes,
      convertedAt: entity.convertedAt.toIso8601String(),
      wasSuccessful: entity.wasSuccessful,
      outputFilePath: entity.outputFilePath,
    );

  final String id;
  final String inputFileName;
  final String outputFileName;
  final String inputFormat;
  final String outputFormat;
  final int inputSizeBytes;
  final int outputSizeBytes;
  final String convertedAt;
  final bool wasSuccessful;
  final String? outputFilePath;

  Map<String, dynamic> toJson() => {
      'id': id,
      'inputFileName': inputFileName,
      'outputFileName': outputFileName,
      'inputFormat': inputFormat,
      'outputFormat': outputFormat,
      'inputSizeBytes': inputSizeBytes,
      'outputSizeBytes': outputSizeBytes,
      'convertedAt': convertedAt,
      'wasSuccessful': wasSuccessful,
      'outputFilePath': outputFilePath,
    };

  HistoryRecord toDomain() => HistoryRecord(
      id: id,
      inputFileName: inputFileName,
      outputFileName: outputFileName,
      inputFormat: inputFormat,
      outputFormat: outputFormat,
      inputSizeBytes: inputSizeBytes,
      outputSizeBytes: outputSizeBytes,
      convertedAt: DateTime.parse(convertedAt),
      wasSuccessful: wasSuccessful,
      outputFilePath: outputFilePath,
    );
}
