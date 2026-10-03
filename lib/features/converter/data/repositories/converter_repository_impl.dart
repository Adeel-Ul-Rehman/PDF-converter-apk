import 'dart:async';

import 'package:flux_convert/core/error/failures.dart';
import 'package:flux_convert/core/usecases/use_case.dart';
import 'package:flux_convert/features/converter/data/datasources/converter_local_datasource.dart';
import 'package:flux_convert/features/converter/data/models/conversion_job_model.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_format.dart';
import 'package:flux_convert/features/converter/domain/entities/conversion_job.dart';
import 'package:flux_convert/features/converter/domain/repositories/converter_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConverterRepositoryImpl — Concrete Repository Implementation
///
/// Converts Exceptions thrown by DataSources to Failures for the Domain.
/// ─────────────────────────────────────────────────────────────────────────────
class ConverterRepositoryImpl implements ConverterRepository {
  ConverterRepositoryImpl(this._localDataSource);

  final ConverterLocalDataSource _localDataSource;

  @override
  Future<Result<ConversionJob>> queueJob({
    required String inputFilePath,
    required String outputFormat,
  }) async {
    try {
      final job = ConversionJob(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        inputFilePath: inputFilePath,
        outputFilePath: '${inputFilePath}_converted.$outputFormat',
        inputFormat: inputFilePath.split('.').last,
        outputFormat: outputFormat,
        status: ConversionStatus.queued,
        createdAt: DateTime.now(),
      );
      await _localDataSource.saveJob(ConversionJobModel.fromDomain(job));
      return Success(job);
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  @override
  Future<Result<ConversionJob>> getJob(String jobId) async {
    try {
      final jobModel = await _localDataSource.getJob(jobId);
      if (jobModel == null) {
        return const FailureResult(StorageFailure(message: 'Job not found in database'));
      }
      return Success(jobModel.toDomain());
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  @override
  Future<Result<void>> cancelJob(String jobId) async {
    try {
      await _localDataSource.deleteJob(jobId);
      return const Success(null);
    } catch (e, stack) {
      return FailureResult(UnknownFailure.fromError(e, stack));
    }
  }

  @override
  Stream<int> watchProgress(String jobId) {
    // Return a dummy stream tracking progress mock values.
    return Stream.periodic(const Duration(milliseconds: 500), (c) => c * 10)
        .take(11);
  }

  @override
  Future<Result<List<ConversionFormat>>> getSupportedFormats() async => Success(ConversionFormat.values.toList());
}
