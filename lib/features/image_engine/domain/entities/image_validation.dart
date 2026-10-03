import 'package:flux_convert/core/error/failures.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ImageValidation
///
/// Report detailing the validation checks performed on an image file.
/// ─────────────────────────────────────────────────────────────────────────────
class ImageValidation {
  const ImageValidation({
    required this.isValid,
    required this.failures,
    this.hasTransparency = false,
    this.isAnimated = false,
    this.width = 0,
    this.height = 0,
  });

  /// True if all image validation passes cleanly.
  final bool isValid;

  /// Specific checks validation failures list.
  final List<Failure> failures;

  /// Exposes transparency state.
  final bool hasTransparency;

  /// Exposes animated state (e.g. GIF, APNG).
  final bool isAnimated;

  /// Raw width.
  final int width;

  /// Raw height.
  final int height;

  /// Helper returning the first failure message if exists.
  String? get firstErrorMessage => failures.isEmpty ? null : failures.first.message;
}
