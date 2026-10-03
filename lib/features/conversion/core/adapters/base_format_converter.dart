import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_result.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_context.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';
import 'package:flux_convert/features/conversion/core/adapters/converter_capabilities.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BaseFormatConverter
///
/// Abstract format-specific converter contract. Exposes descriptors,
/// capabilities, validators, size estimators, and lifecycle hooks.
/// ─────────────────────────────────────────────────────────────────────────────
abstract class BaseFormatConverter {
  const BaseFormatConverter();

  /// Programmatic identifier (e.g. "com.fluxconvert.pdf_to_docx").
  String get converterId;

  /// User-facing description (e.g. "PDF to Word Document Converter").
  String get displayName;

  /// Lowercase extensions this converter accepts as source inputs (e.g. ["pdf"]).
  List<String> get supportedInputFormats;

  /// Lowercase extensions this converter yields as outputs (e.g. ["docx", "txt"]).
  List<String> get supportedOutputFormats;

  /// Set of advanced capability options (like password, metadata retention).
  ConverterCapabilities get capabilities;

  /// Checks if this converter can handle the requested file formats combination.
  bool canConvert(String inputExt, String outputExt) {
    final cleanInput = inputExt.toLowerCase().replaceAll('.', '');
    final cleanOutput = outputExt.toLowerCase().replaceAll('.', '');
    return supportedInputFormats.contains(cleanInput) &&
        supportedOutputFormats.contains(cleanOutput);
  }

  /// Runs converter-specific checks (e.g., checks for password protection, pages limits).
  Future<Result<void>> validate(File file, ConversionSettings settings);

  /// Estimates output file size in bytes based on input settings.
  Future<int> estimateOutputSize(File file, ConversionSettings settings);

  /// Standard conversion loop trigger.
  Future<Result<ConversionResult>> convert(
    ConversionContext context,
    void Function(double progress) onProgress,
  );

  /// Aborts active conversion operations.
  void cancel(String taskId);

  /// Recovers memory footprints and releases locks.
  void dispose();
}
