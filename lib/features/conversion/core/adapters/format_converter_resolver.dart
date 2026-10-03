import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/core/adapters/base_format_converter.dart';
import 'package:flux_convert/features/conversion/core/adapters/format_converter_registry.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FormatConverterResolver
///
/// Resolves the correct format converter adapter using registry mapping.
/// Avoids if-else routing chains by referencing registry dictionary maps.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class FormatConverterResolver {
  /// Resolves the converter supporting the input-to-output path conversion.
  ///
  /// Returns a clean [Result<BaseFormatConverter>] to handle failures gracefully.
  static Result<BaseFormatConverter> resolve(
    String sourceExt,
    String targetExt,
  ) {
    final cleanSource = sourceExt.trim().toLowerCase().replaceAll('.', '');
    final cleanTarget = targetExt.trim().toLowerCase().replaceAll('.', '');

    final converters = FormatConverterRegistry.findByMapping(cleanSource, cleanTarget);

    if (converters.isNotEmpty) {
      // Returns the registered adapter converter (or priority model if multiple exist)
      return Success(converters.first);
    }

    return FailureResult(
      ConversionFailure(
        message: 'No converter adapter registered for .$cleanSource to .$cleanTarget.',
        technicalMessage: 'Registry lookup empty for mapping: ${cleanSource}_to_$cleanTarget',
      ),
    );
  }
}
