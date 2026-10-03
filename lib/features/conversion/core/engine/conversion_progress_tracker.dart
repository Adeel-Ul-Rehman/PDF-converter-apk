import 'package:flux_convert/features/conversion/domain/entities/conversion_enums.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ConversionProgressTracker
///
/// Handles orchestrating task progress rates and stage statuses.
/// ─────────────────────────────────────────────────────────────────────────────
class ConversionProgressTracker {
  ConversionProgressTracker({this.onProgressUpdate});

  /// Event callbacks matching progress shifts.
  final void Function(double progress, ConversionStatus status)? onProgressUpdate;

  double _progress = 0.0;
  ConversionStatus _status = ConversionStatus.idle;

  /// Current progress double value (0.0 to 1.0).
  double get progress => _progress;

  /// Active status stage.
  ConversionStatus get status => _status;

  /// Updates progress parameters and fires listeners.
  void updateProgress(double progress, ConversionStatus status) {
    _progress = progress.clamp(0.0, 1.0);
    _status = status;
    onProgressUpdate?.call(_progress, _status);
  }

  /// Resets tracker values.
  void reset() {
    _progress = 0.0;
    _status = ConversionStatus.idle;
  }
}
