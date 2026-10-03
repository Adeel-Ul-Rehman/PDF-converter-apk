import 'package:flux_convert/features/converter/data/models/conversion_job_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConverterLocalDataSource — Abstract Local Storage Source
///
/// Interface for database or key-value local actions regarding conversion jobs.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class ConverterLocalDataSource {
  Future<void> saveJob(ConversionJobModel job);
  Future<ConversionJobModel?> getJob(String jobId);
  Future<void> deleteJob(String jobId);
}

/// Concrete local data source stub.
class ConverterLocalDataSourceImpl implements ConverterLocalDataSource {
  const ConverterLocalDataSourceImpl();

  @override
  Future<void> saveJob(ConversionJobModel job) async {}

  @override
  Future<ConversionJobModel?> getJob(String jobId) async => null;

  @override
  Future<void> deleteJob(String jobId) async {}
}
