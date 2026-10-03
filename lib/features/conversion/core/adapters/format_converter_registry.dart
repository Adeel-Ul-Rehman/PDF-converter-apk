import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/core/adapters/base_format_converter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// FormatConverterRegistry
///
/// Central registry managing registrations, removals, and lookups.
/// Prevents duplicate registrations.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class FormatConverterRegistry {
  static final Map<String, BaseFormatConverter> _convertersById = {};
  
  // Maps "sourceExt_to_targetExt" -> List of matching converters
  static final Map<String, List<BaseFormatConverter>> _convertersByMapping = {};

  static String _buildMapKey(String sourceExt, String targetExt) =>
      '${sourceExt.trim().toLowerCase()}_to_${targetExt.trim().toLowerCase()}';

  /// Registers a format converter.
  ///
  /// Logs a warning and skips if the converter ID has already been registered.
  static void register(BaseFormatConverter converter) {
    if (_convertersById.containsKey(converter.converterId)) {
      AppLogger.warning(
        'FormatConverterRegistry: Duplicate registration skipped for ID: ${converter.converterId}',
      );
      return;
    }

    _convertersById[converter.converterId] = converter;

    // Index mappings
    for (final source in converter.supportedInputFormats) {
      for (final target in converter.supportedOutputFormats) {
        final key = _buildMapKey(source, target);
        final list = _convertersByMapping.putIfAbsent(key, () => []);
        if (!list.contains(converter)) {
          list.add(converter);
        }
      }
    }
    
    AppLogger.info('FormatConverterRegistry: Registered converter: ${converter.converterId}');
  }

  /// Removes a converter by its identifier.
  static void remove(String converterId) {
    final converter = _convertersById.remove(converterId);
    if (converter == null) return;

    // Clean mappings
    for (final source in converter.supportedInputFormats) {
      for (final target in converter.supportedOutputFormats) {
        final key = _buildMapKey(source, target);
        final list = _convertersByMapping[key];
        if (list != null) {
          list.remove(converter);
          if (list.isEmpty) {
            _convertersByMapping.remove(key);
          }
        }
      }
    }
    
    AppLogger.info('FormatConverterRegistry: Removed converter: $converterId');
  }

  /// Finds a registered converter by its unique identifier.
  static BaseFormatConverter? find(String converterId) => _convertersById[converterId];

  /// Finds all converters supporting a specific format conversion path.
  static List<BaseFormatConverter> findByMapping(String sourceExt, String targetExt) {
    final key = _buildMapKey(sourceExt, targetExt);
    return List.unmodifiable(_convertersByMapping[key] ?? const []);
  }

  /// Returns all registered output formats for a given source extension.
  static List<String> getSupportedOutputs(String sourceExt) {
    final cleanSource = sourceExt.trim().toLowerCase();
    final outputs = <String>{};

    for (final converter in _convertersById.values) {
      if (converter.supportedInputFormats.contains(cleanSource)) {
        outputs.addAll(converter.supportedOutputFormats);
      }
    }
    return outputs.toList();
  }

  /// Gets all registered converters.
  static List<BaseFormatConverter> get allConverters =>
      List.unmodifiable(_convertersById.values);

  /// Clears the registry.
  static void clear() {
    _convertersById.clear();
    _convertersByMapping.clear();
  }
}
