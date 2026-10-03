import 'dart:io';

import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/core/converters/conversion_factory.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_enums.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_result.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_task.dart';
import 'package:flux_convert/features/conversion/core/engine/conversion_storage_manager.dart';
import 'package:flux_convert/features/security/data/services/security_manager.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionEngine
///
/// Framework wrapper orchestrating single conversion pipeline cycles.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionEngine {
  const ConversionEngine(this._securityManager);

  final SecurityManager _securityManager;

  /// Synchronously or one-off processes a file conversion outside the scheduling queue.
  Future<Result<ConversionResult>> executeDirect(
    String inputPath,
    String targetExt,
    void Function(double progress) onProgress,
  ) async {
    final stopWatch = Stopwatch()..start();
    try {
      final file = File(inputPath);
      final fileName = file.path.split('/').last.split(r'\').last;
      final fileBase = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final sourceExt = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
          : '';

      // ── 1. Allocate destination storage path ───────────────────────────────
      onProgress(0.05);
      final destResult = await ConversionStorageManager.getDestinationPath(
        fileBase,
        targetExt,
      );

      if (destResult.isFailure) {
        return FailureResult(destResult.failure);
      }

      final destPath = destResult.value;

      // ── 2. Create mock task for compatibility ───────────────────────────────
      final tempTask = ConversionTask(
        id: 'direct_run',
        inputPath: inputPath,
        outputPath: destPath,
        inputExtension: sourceExt,
        outputExtension: targetExt,
        status: ConversionStatus.preparing,
        progress: 0.10,
        createdTime: DateTime.now(),
      );

      // ── 3. Validate task parameters via SecurityManager ────────────────────
      onProgress(0.10);
      final validation = await _securityManager.authorizeAndValidateConversion(
        inputPath: inputPath,
        targetExtension: targetExt,
      );
      if (validation.isFailure) {
        return FailureResult(validation.failure);
      }

      // ── 4. Retrieve Converter from factory ────────────────────────────────
      onProgress(0.20);
      final factoryResult = ConversionFactory.getConverter(sourceExt, targetExt);
      if (factoryResult.isFailure) {
        return FailureResult(factoryResult.failure);
      }

      final converter = factoryResult.value;

      // ── 5. Run conversion ──────────────────────────────────────────────────
      onProgress(0.30);
      final conversionResult = await converter.convert(tempTask, (progressVal) {
        // Map 0.0-1.0 to 0.30-0.90 in direct runner
        onProgress(0.30 + (progressVal * 0.60));
      });

      stopWatch.stop();

      if (conversionResult.isSuccess) {
        onProgress(1.0);
        return Success(conversionResult.value);
      } else {
        return FailureResult(conversionResult.failure);
      }
    } catch (e, stack) {
      stopWatch.stop();
      return FailureResult(
        UnknownFailure(
          message: 'Unhandled error in direct conversion flow.',
          technicalMessage: e.toString(),
          stackTrace: stack,
        ),
      );
    }
  }
}
