import 'package:flux_convert/features/history/domain/entities/conversion_history.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionHistoryModel
///
/// Data model wrapping [ConversionHistory] for SQLite or JSON storage.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionHistoryModel {
  const ConversionHistoryModel({
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
    required this.conversionDurationMs,
    required this.conversionStatus,
    required this.createdDateEpoch,
    required this.completedDateEpoch,
    this.errorMessage,
    this.thumbnailPath,
  });

  /// Creates a model from domain entity.
  factory ConversionHistoryModel.fromDomain(ConversionHistory entity) => ConversionHistoryModel(
      id: entity.id,
      conversionId: entity.conversionId,
      sourceFileName: entity.sourceFileName,
      sourceFilePath: entity.sourceFilePath,
      destinationFileName: entity.destinationFileName,
      destinationFilePath: entity.destinationFilePath,
      sourceFormat: entity.sourceFormat,
      destinationFormat: entity.destinationFormat,
      originalFileSize: entity.originalFileSize,
      convertedFileSize: entity.convertedFileSize,
      conversionDurationMs: entity.conversionDuration.inMilliseconds,
      conversionStatus: entity.conversionStatus,
      createdDateEpoch: entity.createdDate.millisecondsSinceEpoch,
      completedDateEpoch: entity.completedDate.millisecondsSinceEpoch,
      errorMessage: entity.errorMessage,
      thumbnailPath: entity.thumbnailPath,
    );

  factory ConversionHistoryModel.fromJson(Map<String, dynamic> json) =>
      ConversionHistoryModel(
        id: json['id'] as String,
        conversionId: json['conversionId'] as String,
        sourceFileName: json['sourceFileName'] as String,
        sourceFilePath: json['sourceFilePath'] as String,
        destinationFileName: json['destinationFileName'] as String,
        destinationFilePath: json['destinationFilePath'] as String,
        sourceFormat: json['sourceFormat'] as String,
        destinationFormat: json['destinationFormat'] as String,
        originalFileSize: json['originalFileSize'] as int,
        convertedFileSize: json['convertedFileSize'] as int,
        conversionDurationMs: json['conversionDurationMs'] as int,
        conversionStatus: json['conversionStatus'] as String,
        createdDateEpoch: json['createdDateEpoch'] as int,
        completedDateEpoch: json['completedDateEpoch'] as int,
        errorMessage: json['errorMessage'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
      );

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
  final int conversionDurationMs;
  final String conversionStatus;
  final int createdDateEpoch;
  final int completedDateEpoch;
  final String? errorMessage;
  final String? thumbnailPath;

  /// Converts this model to rich domain entity.
  ConversionHistory toDomain() => ConversionHistory(
      id: id,
      conversionId: conversionId,
      sourceFileName: sourceFileName,
      sourceFilePath: sourceFilePath,
      destinationFileName: destinationFileName,
      destinationFilePath: destinationFilePath,
      sourceFormat: sourceFormat,
      destinationFormat: destinationFormat,
      originalFileSize: originalFileSize,
      convertedFileSize: convertedFileSize,
      conversionDuration: Duration(milliseconds: conversionDurationMs),
      conversionStatus: conversionStatus,
      createdDate: DateTime.fromMillisecondsSinceEpoch(createdDateEpoch),
      completedDate: DateTime.fromMillisecondsSinceEpoch(completedDateEpoch),
      errorMessage: errorMessage,
      thumbnailPath: thumbnailPath,
    );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversionId': conversionId,
        'sourceFileName': sourceFileName,
        'sourceFilePath': sourceFilePath,
        'destinationFileName': destinationFileName,
        'destinationFilePath': destinationFilePath,
        'sourceFormat': sourceFormat,
        'destinationFormat': destinationFormat,
        'originalFileSize': originalFileSize,
        'convertedFileSize': convertedFileSize,
        'conversionDurationMs': conversionDurationMs,
        'conversionStatus': conversionStatus,
        'createdDateEpoch': createdDateEpoch,
        'completedDateEpoch': completedDateEpoch,
        'errorMessage': errorMessage,
        'thumbnailPath': thumbnailPath,
      };
}
