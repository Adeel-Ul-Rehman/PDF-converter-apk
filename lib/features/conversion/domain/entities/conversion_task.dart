import 'package:flux_convert/features/conversion/domain/entities/conversion_enums.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionTask
///
/// Data model representing a conversion job in the pipeline queue.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionTask {
  const ConversionTask({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    required this.inputExtension,
    required this.outputExtension,
    required this.status,
    required this.progress,
    required this.createdTime,
    this.startedTime,
    this.finishedTime,
    this.failure,
    this.duration,
  });

  /// Unique task identifier.
  final String id;

  /// Absolute file system path of the input source.
  final String inputPath;

  /// Absolute file system path of the target destination output.
  final String outputPath;

  /// Lowercase extension string of the source file.
  final String inputExtension;

  /// Lowercase extension string of the target output file.
  final String outputExtension;

  /// Operational state of this task in the execution queue.
  final ConversionStatus status;

  /// Progress indicator double ranging from 0.0 to 1.0.
  final double progress;

  /// Timestamp of when the task was initially queued.
  final DateTime createdTime;

  /// Timestamp of when execution commenced.
  final DateTime? startedTime;

  /// Timestamp of when completion or terminal status was reached.
  final DateTime? finishedTime;

  /// Human-readable error logs if status is [ConversionStatus.failed].
  final String? failure;

  /// Total duration taken to complete the process.
  final Duration? duration;

  /// Utility getter to parse input file name.
  String get fileName => inputPath.split('/').last.split(r'\').last;

  /// Creates a copy of this task with modified properties.
  ConversionTask copyWith({
    String? id,
    String? inputPath,
    String? outputPath,
    String? inputExtension,
    String? outputExtension,
    ConversionStatus? status,
    double? progress,
    DateTime? createdTime,
    DateTime? startedTime,
    DateTime? finishedTime,
    String? failure,
    Duration? duration,
  }) => ConversionTask(
      id: id ?? this.id,
      inputPath: inputPath ?? this.inputPath,
      outputPath: outputPath ?? this.outputPath,
      inputExtension: inputExtension ?? this.inputExtension,
      outputExtension: outputExtension ?? this.outputExtension,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdTime: createdTime ?? this.createdTime,
      startedTime: startedTime ?? this.startedTime,
      finishedTime: finishedTime ?? this.finishedTime,
      failure: failure ?? this.failure,
      duration: duration ?? this.duration,
    );

  @override
  String toString() =>
      'ConversionTask[$id](${status.name}): progress=$progress, error=$failure';
}
