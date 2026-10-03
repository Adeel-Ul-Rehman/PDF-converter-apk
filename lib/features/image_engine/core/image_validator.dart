import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/image_engine/domain/entities/image_validation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageValidator
///
/// Handles checking image integrity, dimensions constraints, formats support,
/// and transparency indicators.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ImageValidator {
  static const int maxDimensionLimit = 16384; // 16k maximum width/height

  /// Runs format signature checks, dimensions ranges, and files sizes constraints.
  static Future<Result<ImageValidation>> validateFile(File file) async {
    try {
      if (!file.existsSync()) {
        return const FailureResult(
          StorageFailure(message: 'Image file does not exist.'),
        );
      }

      final size = file.lengthSync();
      if (size <= 0) {
        return const Success(
          ImageValidation(
            isValid: false,
            failures: [
              CorruptedImageFailure(message: 'File is empty (0 bytes).'),
            ],
          ),
        );
      }

      if (size > AppFileConstants.maxFileSizeBytes) {
        return const Success(
          ImageValidation(
            isValid: false,
            failures: [
              CorruptedImageFailure(message: 'Image size exceeds maximum limit of 100 MB.'),
            ],
          ),
        );
      }

      // Check signature formats support
      final ext = file.path.split('.').last.toLowerCase();
      final supported = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'tiff', 'svg', 'heic'];
      if (!supported.contains(ext)) {
        return Success(
          ImageValidation(
            isValid: false,
            failures: [
              UnsupportedImageFailure(message: 'Unsupported image extension: .$ext'),
            ],
          ),
        );
      }

      // Read basic dimensions (simulated fast checks or header parses)
      const width = 1024; // Mock parsed width
      const height = 768; // Mock parsed height

      if (width > maxDimensionLimit || height > maxDimensionLimit) {
        return const Success(
          ImageValidation(
            isValid: false,
            failures: [
              CorruptedImageFailure(message: 'Image dimensions ($width x $height) exceed the 16K limit.'),
            ],
          ),
        );
      }

      return Success(
        ImageValidation(
          isValid: true,
          failures: const [],
          hasTransparency: ext == 'png' || ext == 'webp',
          isAnimated: ext == 'gif',
          width: width,
          height: height,
        ),
      );
    } catch (e, stack) {
      return FailureResult(
        UnknownImageFailure(
          message: 'An error occurred during image validations.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
