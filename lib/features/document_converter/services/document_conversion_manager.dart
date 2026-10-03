import 'dart:async';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_request.dart';
import 'package:flux_convert/features/document_converter/domain/entities/document_conversion_response.dart';
import 'package:flux_convert/features/document_converter/shared/dispatcher/document_conversion_dispatcher.dart';
import 'package:flux_convert/features/document_converter/shared/progress/document_conversion_progress_tracker.dart';
import 'package:flux_convert/features/document_converter/services/document_conversion_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionManager
///
/// Central facade coordinating validators pipelines, conversion services,
/// temporary files cleaning, and progress listeners.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentConversionManager {
  DocumentConversionManager(this._service)
      : _progressTracker = DocumentConversionProgressTracker();

  final DocumentConversionService _service;
  final DocumentConversionProgressTracker _progressTracker;

  /// Exposes the progress tracker registrations.
  DocumentConversionProgressTracker get progressTracker => _progressTracker;

  /// Executes conversion pipelines sequentially.
  Future<Result<DocumentConversionResponse>> executeConversion({
    required String taskId,
    required DocumentConversionRequest request,
    required void Function(double progress, String step) onProgress,
  }) async {
    _progressTracker.register(taskId, onProgress);

    try {
      // ── 1. Preparing phase ─────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 0.0, DocumentProgressSteps.preparing);
      final sourcePath = request.document.filePath;
      final targetExt = request.targetFormat.extension;
      
      // ── 2. Validating phase ────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 0.1, DocumentProgressSteps.validating);
      final validation = await DocumentConversionDispatcher.runValidationPipeline(
        sourcePath: sourcePath,
        targetFormat: targetExt,
        outputDir: request.outputDirectory,
      );

      if (validation.isFailure) {
        _progressTracker.updateProgress(taskId, 0.0, DocumentProgressSteps.failed);
        _progressTracker.remove(taskId);
        return FailureResult(validation.failure);
      }

      // ── 3. Reading phase ───────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 0.25, DocumentProgressSteps.reading);

      // Resolve output path name conflicts
      final finalOutputPath = await DocumentConversionDispatcher.resolveUniqueOutputPath(
        outputDir: request.outputDirectory,
        sourceFileName: request.document.metadata.fileName,
        targetFormat: targetExt,
      );

      // ── 4. Processing phase ────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 0.4, DocumentProgressSteps.processing);
      
      final Result<DocumentConversionResponse> result;
      final sourceExt = request.document.format.extension;

      if (sourceExt == 'txt' && targetExt == 'pdf') {
        result = await _service.executeIsolateConversion(
          taskId: taskId,
          entryPoint: DocumentConversionService.isolateTxtToPdf,
          baseArgs: {
            'inputPath': sourcePath,
            'outputPath': finalOutputPath,
            'keepMetadata': request.keepMetadata,
          },
          onProgress: (p) => _progressTracker.updateProgress(
            taskId,
            0.4 + (p * 0.4),
            DocumentProgressSteps.processing,
          ),
        );
      } else if (sourceExt == 'pdf' && targetExt == 'txt') {
        result = await _service.executeIsolateConversion(
          taskId: taskId,
          entryPoint: DocumentConversionService.isolatePdfToTxt,
          baseArgs: {
            'inputPath': sourcePath,
            'outputPath': finalOutputPath,
          },
          onProgress: (p) => _progressTracker.updateProgress(
            taskId,
            0.4 + (p * 0.4),
            DocumentProgressSteps.processing,
          ),
        );
      } else {
        result = FailureResult(
          ConversionFailure(
            message: 'Conversion from ${sourceExt.toUpperCase()} to ${targetExt.toUpperCase()} is not implemented offline.',
          ),
        );
      }

      if (result.isFailure) {
        _progressTracker.updateProgress(taskId, 0.0, DocumentProgressSteps.failed);
        _progressTracker.remove(taskId);
        return FailureResult(result.failure);
      }

      // ── 5. Writing phase ───────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 0.9, DocumentProgressSteps.writing);

      // ── 6. Cleaning phase ──────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 0.95, DocumentProgressSteps.cleaning);

      // ── 7. Completion phase ────────────────────────────────────────────────
      _progressTracker.updateProgress(taskId, 1.0, DocumentProgressSteps.completed);
      _progressTracker.remove(taskId);

      return Success(result.value);
    } catch (e, stack) {
      _progressTracker.updateProgress(taskId, 0.0, DocumentProgressSteps.failed);
      _progressTracker.remove(taskId);
      return FailureResult(
        ConversionFailure(
          message: 'Document conversion aborted due to unknown errors.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  /// Cancels an active conversion.
  Future<void> cancelActiveTask(String taskId) async {
    _progressTracker.updateProgress(taskId, 0.0, DocumentProgressSteps.cancelled);
    _progressTracker.remove(taskId);
    await _service.cancelTask(taskId);
  }
}
