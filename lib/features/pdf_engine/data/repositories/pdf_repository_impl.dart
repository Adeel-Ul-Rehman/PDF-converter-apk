import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/pdf_engine/core/pdf_engine.dart';
import 'package:flux_convert/features/pdf_engine/core/pdf_validator.dart';
import 'package:flux_convert/features/pdf_engine/domain/entities/pdf_task.dart';
import 'package:flux_convert/features/pdf_engine/domain/repositories/pdf_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PdfRepositoryImpl
///
/// Implements [PdfRepository] by spawning independent background isolates.
/// Establishes message channels to route progress updates without blocking UI threads.
/// ─────────────────────────────────────────────────────────────────────────────
class PdfRepositoryImpl implements PdfRepository {
  PdfRepositoryImpl();

  final Map<String, Isolate> _runningIsolates = {};
  final Map<String, ReceivePort> _runningReceivePorts = {};

  /// Spawns a background isolate and tracks progress updates via ReceivePorts.
  Future<Result<T>> _runInIsolate<T>({
    required String taskId,
    required void Function(Map<String, dynamic>) entryPoint,
    required Map<String, dynamic> baseArgs,
    required void Function(double progress) onProgress,
  }) async {
    final receivePort = ReceivePort();
    final progressPort = ReceivePort();
    _runningReceivePorts[taskId] = receivePort;

    final args = Map<String, dynamic>.from(baseArgs)
      ..['replyPort'] = receivePort.sendPort
      ..['progressPort'] = progressPort.sendPort;

    try {
      final isolate = await Isolate.spawn(entryPoint, args);
      _runningIsolates[taskId] = isolate;

      // Track progress updates from isolate
      final progressSub = progressPort.listen((message) {
        if (message is double) {
          onProgress(message);
        }
      });

      final completer = Completer<Result<T>>();

      receivePort.listen((message) {
        progressSub.cancel();
        progressPort.close();
        _cleanupTask(taskId);

        if (message is T) {
          completer.complete(Success(message));
        } else if (message is Exception) {
          completer.complete(
            FailureResult(
              ConversionFailure(
                message: message.toString().replaceAll('Exception: ', ''),
                technicalMessage: 'Isolate returned exception status.',
              ),
            ),
          );
        } else {
          completer.complete(
            const FailureResult(
              ConversionFailure(message: 'Unknown parsing response from isolate.'),
            ),
          );
        }
      });

      return await completer.future;
    } catch (e, stack) {
      receivePort.close();
      progressPort.close();
      _cleanupTask(taskId);
      return FailureResult(
        ConversionFailure(
          message: 'Failed to spawn background thread worker.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }

  void _cleanupTask(String taskId) {
    _runningIsolates.remove(taskId)?.kill();
    _runningReceivePorts.remove(taskId)?.close();
  }

  @override
  Future<Result<String>> imageToPdf({
    required String taskId,
    required ImageToPdfParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    // Validate image files exist first
    for (final path in params.imagePaths) {
      if (!File(path).existsSync()) {
        return FailureResult(
          StorageFailure(message: 'Source image file not found: $path'),
        );
      }
    }

    return _runInIsolate<String>(
      taskId: taskId,
      entryPoint: PdfEngine.isolateImageToPdf,
      baseArgs: {
        'imagePaths': params.imagePaths,
        'outputPath': outputPath,
        'margin': params.marginDouble,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<List<String>>> pdfToImage({
    required String taskId,
    required PdfToImageParams params,
    required String outputDir,
    required void Function(double progress) onProgress,
  }) async {
    final validation = await PdfValidator.validateFile(File(params.pdfPath));
    if (validation.isFailure) {
      return FailureResult(validation.failure);
    }

    return _runInIsolate<List<String>>(
      taskId: taskId,
      entryPoint: PdfEngine.isolatePdfToImage,
      baseArgs: {
        'pdfPath': params.pdfPath,
        'outputDir': outputDir,
        'pageRange': params.pageRange,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> mergePdf({
    required String taskId,
    required PdfMergeParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    for (final path in params.pdfPaths) {
      final validation = await PdfValidator.validateFile(File(path));
      if (validation.isFailure) {
        return FailureResult(validation.failure);
      }
    }

    return _runInIsolate<String>(
      taskId: taskId,
      entryPoint: PdfEngine.isolateMergePdf,
      baseArgs: {
        'pdfPaths': params.pdfPaths,
        'outputPath': outputPath,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<List<String>>> splitPdf({
    required String taskId,
    required PdfSplitParams params,
    required String outputDir,
    required void Function(double progress) onProgress,
  }) async {
    final validation = await PdfValidator.validateFile(File(params.pdfPath));
    if (validation.isFailure) {
      return FailureResult(validation.failure);
    }

    return _runInIsolate<List<String>>(
      taskId: taskId,
      entryPoint: PdfEngine.isolateSplitPdf,
      baseArgs: {
        'pdfPath': params.pdfPath,
        'outputDir': outputDir,
        'splitRanges': params.splitRanges,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> rotatePdf({
    required String taskId,
    required PdfRotateParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    final validation = await PdfValidator.validateFile(File(params.pdfPath));
    if (validation.isFailure) {
      return FailureResult(validation.failure);
    }

    return _runInIsolate<String>(
      taskId: taskId,
      entryPoint: PdfEngine.isolateRotatePdf,
      baseArgs: {
        'pdfPath': params.pdfPath,
        'outputPath': outputPath,
        'angle': params.angleDegrees,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> compressPdf({
    required String taskId,
    required PdfCompressParams params,
    required String outputPath,
    required void Function(double progress) onProgress,
  }) async {
    final validation = await PdfValidator.validateFile(File(params.pdfPath));
    if (validation.isFailure) {
      return FailureResult(validation.failure);
    }

    return _runInIsolate<String>(
      taskId: taskId,
      entryPoint: PdfEngine.isolateCompressPdf,
      baseArgs: {
        'pdfPath': params.pdfPath,
        'outputPath': outputPath,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<void>> cancelTask(String taskId) async {
    _cleanupTask(taskId);
    AppLogger.info('PdfRepositoryImpl: Terminated background isolate worker for $taskId');
    return const Success(null);
  }
}
