import 'dart:io';

import 'package:flux_convert/features/conversion/core/adapters/conversion_metadata.dart';
import 'package:flux_convert/features/conversion/core/adapters/conversion_settings.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CancellationToken
///
/// Standard token pattern to abort active pipeline execution loops.
/// ─────────────────────────────────────────────────────────────────────────────
class CancellationToken {
  bool _isCancelled = false;

  /// Returns true if user has cancelled the active execution task.
  bool get isCancelled => _isCancelled;

  /// Aborts active tasks checking this token.
  void cancel() {
    _isCancelled = true;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionContext
///
/// Packaged arguments passed down the adapter pipeline.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionContext {
  const ConversionContext({
    required this.inputFile,
    required this.outputPath,
    required this.tempDirectory, this.settings = ConversionSettings.defaultSettings,
    this.metadata = const ConversionMetadata(),
    this.cancellationToken,
  });

  /// Native File pointer of the input file.
  final File inputFile;

  /// Target file path destination.
  final String outputPath;

  /// Custom compression and folder output settings.
  final ConversionSettings settings;

  /// Pre-extracted format parameters.
  final ConversionMetadata metadata;

  /// Temp working directory.
  final Directory tempDirectory;

  /// Token checking cancellation triggers.
  final CancellationToken? cancellationToken;
}
