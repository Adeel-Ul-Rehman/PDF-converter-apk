import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_metadata.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_task.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_validation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageConversionRepository
///
/// Repository contract detailing offline image analysis, validations,
/// format conversion, and memory-safe thumbnail generation.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class ImageConversionRepository {
  /// Runs readable, corrupted, password/locks, dimensions and size checks.
  Future<Result<ImageValidation>> validateImage(String filePath);

  /// Extracts dimensions, colors, transparency, formats and dates.
  Future<Result<ImageMetadata>> extractMetadata(String filePath);

  /// Launches the formatting and resizing pipeline on a background isolate.
  Future<Result<String>> convertImage({
    required ImageTask task,
    required void Function(double progress) onProgress,
  });

  /// Generates a cached downscaled memory-efficient thumbnail.
  Future<Result<String>> generateThumbnail({
    required String filePath,
    required String cacheDir,
    required int maxDimension,
  });

  /// Aborts active conversion operations.
  Future<Result<void>> cancelTask(String taskId);
}
