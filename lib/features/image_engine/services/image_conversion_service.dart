import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/image_engine/core/image_progress_tracker.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_task.dart';
import 'package:flux_convert/features/image_engine/domain/repositories/image_conversion_repository.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageConversionService
///
/// High-level service managing formats mapping, validations, cache folders
/// lookups, and progress registries.
/// ─────────────────────────────────────────────────────────────────────────────
class ImageConversionService {
  ImageConversionService(this._repository) : _progressTracker = ImageProgressTracker();

  final ImageConversionRepository _repository;
  final ImageProgressTracker _progressTracker;

  /// Exposes the progress tracker registrar.
  ImageProgressTracker get progressTracker => _progressTracker;

  /// Submits an image task for formatting and scaling.
  Future<Result<String>> processImage({
    required ImageTask task,
    required void Function(double progress) onProgress,
  }) async {
    _progressTracker.register(task.taskId, onProgress);

    final result = await _repository.convertImage(
      task: task,
      onProgress: (p) => _progressTracker.updateProgress(task.taskId, p),
    );

    _progressTracker.remove(task.taskId);
    return result;
  }

  /// Generates a downscaled memory-efficient thumbnail.
  Future<Result<String>> generateThumbnail({
    required String filePath,
    required String cacheDir,
    int maxDimension = 200,
  }) => _repository.generateThumbnail(
      filePath: filePath,
      cacheDir: cacheDir,
      maxDimension: maxDimension,
    );

  /// Aborts active conversion operations.
  Future<Result<void>> cancelActiveTask(String taskId) async {
    _progressTracker.remove(taskId);
    return _repository.cancelTask(taskId);
  }
}
