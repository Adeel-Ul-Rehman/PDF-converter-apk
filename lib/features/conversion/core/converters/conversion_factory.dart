import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/core/converters/base_converter.dart';
import 'package:flux_convert/features/conversion/core/converters/conversion_registry.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionFactory
///
/// Looks up and instantiates the correct converter based on source and target formats.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ConversionFactory {
  /// Looks up and returns a [BaseConverter] for the requested extensions.
  ///
  /// Returns [Result<BaseConverter>] to cleanly wrap missing mappings without throwing.
  static Result<BaseConverter> getConverter(
    String sourceExt,
    String targetExt,
  ) {
    final cleanSource = sourceExt.trim().toLowerCase();
    final cleanTarget = targetExt.trim().toLowerCase();

    final converter = ConversionRegistry.getConverter(cleanSource, cleanTarget);
    if (converter != null) {
      return Success(converter);
    }

    return FailureResult(
      ValidationError(
        message: 'No converter registered to transform .$cleanSource to .$cleanTarget.',
        technicalMessage: 'Registry lookup failed for key: ${cleanSource}_to_$cleanTarget',
      ),
    );
  }
}
