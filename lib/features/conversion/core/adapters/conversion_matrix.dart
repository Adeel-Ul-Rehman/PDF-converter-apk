import 'package:flux_convert/features/conversion/core/adapters/format_converter_registry.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionMatrix
///
/// Centralized mapping matrix querying converter registry capabilities.
/// The UI queries this matrix to render dynamic choices.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ConversionMatrix {
  /// Comprehensive collection of all supported system extensions.
  static const List<String> allFormats = [
    // Documents
    'pdf', 'doc', 'docx', 'txt', 'rtf', 'html', 'odt',
    // Presentations
    'ppt', 'pptx',
    // Spreadsheets
    'xls', 'xlsx', 'csv', 'ods',
    // Images
    'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'tiff', 'svg', 'heic',
  ];

  /// Checks if a pathway is currently active/registered.
  static bool isPathSupported(String inputExt, String outputExt) {
    final cleanInput = inputExt.trim().toLowerCase().replaceAll('.', '');
    final cleanOutput = outputExt.trim().toLowerCase().replaceAll('.', '');
    
    final matches = FormatConverterRegistry.findByMapping(cleanInput, cleanOutput);
    return matches.isNotEmpty;
  }

  /// Returns target formats available for a selected source extension.
  static List<String> getAvailableOutputs(String inputExt) {
    final cleanInput = inputExt.trim().toLowerCase().replaceAll('.', '');
    return FormatConverterRegistry.getSupportedOutputs(cleanInput);
  }

  /// Returns a full map of active mappings (source -> list of output formats).
  static Map<String, List<String>> getActiveMatrix() {
    final matrix = <String, List<String>>{};
    for (final format in allFormats) {
      final outputs = getAvailableOutputs(format);
      if (outputs.isNotEmpty) {
        matrix[format] = outputs;
      }
    }
    return matrix;
  }
}
