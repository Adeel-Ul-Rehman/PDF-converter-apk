import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/image_engine/core/image_conversion_engine.dart';
import 'package:flux_convert/features/image_engine/core/image_metadata_extractor.dart';
import 'package:flux_convert/features/image_engine/core/image_validator.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_metadata.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_task.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_validation.dart';
import 'package:flux_convert/features/image_engine/domain/repositories/image_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageConversionRepositoryImpl
///
/// Coordinates image validations, EXIF metadata parser, and launches conversion
/// threads on background isolates.
/// ─────────────────────────────────────────────────────────────────────────────
class ImageConversionRepositoryImpl implements ImageConversionRepository {
  ImageConversionRepositoryImpl();

  final Map<String, Isolate> _runningIsolates = {};
  final Map<String, ReceivePort> _runningReceivePorts = {};

  /// Spawns background isolates for processing.
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
              ConversionFailure(message: 'Unknown image processing response from isolate.'),
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
          message: 'Failed to spawn image background thread worker.',
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
  Future<Result<ImageValidation>> validateImage(String filePath) => ImageValidator.validateFile(File(filePath));

  @override
  Future<Result<ImageMetadata>> extractMetadata(String filePath) => ImageMetadataExtractor.extract(File(filePath));

  @override
  Future<Result<String>> convertImage({
    required ImageTask task,
    required void Function(double progress) onProgress,
  }) async {
    final validation = await validateImage(task.sourcePath);
    if (validation.isFailure) {
      return FailureResult(validation.failure);
    }

    if (!validation.value.isValid) {
      return FailureResult(
        ConversionFailure(
          message: validation.value.firstErrorMessage ?? 'Image validation failed.',
        ),
      );
    }

    return _runInIsolate<String>(
      taskId: task.taskId,
      entryPoint: ImageConversionEngine.isolateConvertImage,
      baseArgs: {
        'sourcePath': task.sourcePath,
        'outputPath': task.outputPath,
        'targetFormat': task.targetFormat,
        'quality': task.settings.outputQuality,
      },
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> generateThumbnail({
    required String filePath,
    required String cacheDir,
    required int maxDimension,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return const FailureResult(StorageFailure(message: 'File not found.'));
    }

    final name = filePath.split('/').last.split(r'\').last;
    final thumbPath = '$cacheDir/thumb_$name.png';

    return _runInIsolate<String>(
      taskId: 'thumb_$name',
      entryPoint: ImageConversionEngine.isolateGenerateThumbnail,
      baseArgs: {
        'sourcePath': filePath,
        'outputPath': thumbPath,
        'maxDimension': maxDimension,
      },
      onProgress: (_) {},
    );
  }

  @override
  Future<Result<void>> cancelTask(String taskId) async {
    _cleanupTask(taskId);
    AppLogger.info('ImageConversionRepositoryImpl: Terminated isolate worker for $taskId');
    return const Success(null);
  }
}
