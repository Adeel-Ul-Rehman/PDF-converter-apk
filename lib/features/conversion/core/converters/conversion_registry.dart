import 'package:flux_convert/features/conversion/core/converters/base_converter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionRegistry
///
/// Registry storing mappings between source formats, target formats,
/// and their concrete converter executors.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ConversionRegistry {
  static final Map<String, BaseConverter> _registry = {};

  /// Formats the registration key from source and target extensions.
  static String _buildKey(String sourceExt, String targetExt) =>
      '${sourceExt.trim().toLowerCase()}_to_${targetExt.trim().toLowerCase()}';

  /// Registers a converter instance for a given format mapping.
  static void register(
    String sourceExt,
    String targetExt,
    BaseConverter converter,
  ) {
    final key = _buildKey(sourceExt, targetExt);
    _registry[key] = converter;
  }

  /// Retrieves a registered converter for a format mapping, if exists.
  static BaseConverter? getConverter(String sourceExt, String targetExt) {
    final key = _buildKey(sourceExt, targetExt);
    return _registry[key];
  }

  /// Checks if a format conversion path is registered.
  static bool isSupported(String sourceExt, String targetExt) {
    final key = _buildKey(sourceExt, targetExt);
    return _registry.containsKey(key);
  }

  /// Clears the registry mappings. Helpful for unit testing.
  static void clear() {
    _registry.clear();
  }
}
