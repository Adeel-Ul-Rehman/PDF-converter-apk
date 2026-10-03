import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_job.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConverterRepository — Domain Repository Interface
///
/// Defines the abstraction for conversion jobs.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class ConverterRepository {
  /// Queues a new conversion job.
  Future<Result<ConversionJob>> queueJob({
    required String inputFilePath,
    required String outputFormat,
  });

  /// Fetches details of a specific conversion job.
  Future<Result<ConversionJob>> getJob(String jobId);

  /// Cancels a pending or active job.
  Future<Result<void>> cancelJob(String jobId);

  /// Emits updates for a conversion task's progress percent (0 - 100).
  Stream<int> watchProgress(String jobId);

  /// Lists all formats supported by the engine.
  Future<Result<List<ConversionFormat>>> getSupportedFormats();
}
