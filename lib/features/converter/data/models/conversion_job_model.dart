import 'package:flux_convert/features/converter/domain/entities/conversion_job.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionJobModel — Data Model for Local/Network Serialization
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionJobModel {
  const ConversionJobModel({
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

  /// Map JSON map to a model instance.
  factory ConversionJobModel.fromJson(Map<String, dynamic> json) => ConversionJobModel(
      id: json['id'] as String,
      inputFilePath: json['inputFilePath'] as String,
      outputFilePath: json['outputFilePath'] as String,
      inputFormat: json['inputFormat'] as String,
      outputFormat: json['outputFormat'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      completedAt: json['completedAt'] as String?,
      errorMessage: json['errorMessage'] as String?,
      progressPercent: json['progressPercent'] as int? ?? 0,
    );

  /// Map from domain entity.
  factory ConversionJobModel.fromDomain(ConversionJob entity) => ConversionJobModel(
      id: entity.id,
      inputFilePath: entity.inputFilePath,
      outputFilePath: entity.outputFilePath,
      inputFormat: entity.inputFormat,
      outputFormat: entity.outputFormat,
      status: entity.status.name,
      createdAt: entity.createdAt.toIso8601String(),
      completedAt: entity.completedAt?.toIso8601String(),
      errorMessage: entity.errorMessage,
      progressPercent: entity.progressPercent,
    );

  final String id;
  final String inputFilePath;
  final String outputFilePath;
  final String inputFormat;
  final String outputFormat;
  final String status;
  final String createdAt;
  final String? completedAt;
  final String? errorMessage;
  final int progressPercent;

  /// Serialize this model instance to a JSON map.
  Map<String, dynamic> toJson() => {
      'id': id,
      'inputFilePath': inputFilePath,
      'outputFilePath': outputFilePath,
      'inputFormat': inputFormat,
      'outputFormat': outputFormat,
      'status': status,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'errorMessage': errorMessage,
      'progressPercent': progressPercent,
    };

  /// Map to domain entity.
  ConversionJob toDomain() => ConversionJob(
      id: id,
      inputFilePath: inputFilePath,
      outputFilePath: outputFilePath,
      inputFormat: inputFormat,
      outputFormat: outputFormat,
      status: ConversionStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => ConversionStatus.failed,
      ),
      createdAt: DateTime.parse(createdAt),
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
      errorMessage: errorMessage,
      progressPercent: progressPercent,
    );
}
