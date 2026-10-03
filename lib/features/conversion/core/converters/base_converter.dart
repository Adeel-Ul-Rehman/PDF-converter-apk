import 'package:flux_convert/core/core.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_result.dart';
import 'package:flux_convert/features/conversion/domain/entities/conversion_task.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BaseConverter
///
/// Abstract interface contract defining format conversion executions.
/// Every format converter (e.g. PDF to Image, TXT to PDF) must implement this.
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class BaseConverter {
  /// Executes the core conversion process.
  ///
  /// Listens to progress triggers using [onProgress] reporting values from 0.0 to 1.0.
  /// Returns a [Result<ConversionResult>] success wrapper, and never throws exceptions.
  Future<Result<ConversionResult>> convert(
    ConversionTask task,
    void Function(double progress) onProgress,
  );
}
