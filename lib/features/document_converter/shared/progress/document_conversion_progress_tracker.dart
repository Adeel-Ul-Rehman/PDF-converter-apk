import 'dart:async';

import 'package:flux_convert/core/core.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DocumentConversionProgressTracker
///
/// Progress listener managing document processing status milestones.
/// ─────────────────────────────────────────────────────────────────────────────
class DocumentConversionProgressTracker {
  final Map<String, void Function(double progress, String step)> _callbacks = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  /// Registers a task ID with its respective progress callback.
  void register(String taskId, void Function(double progress, String step) onProgress) {
    _callbacks[taskId] = onProgress;
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[taskId] = controller;
    controller.stream.listen((map) {
      final p = map['progress'] as double;
      final s = map['step'] as String;
      onProgress(p, s);
    });
  }

  /// Sends progress and milestone info to the listener.
  void updateProgress(String taskId, double progress, String step) {
    AppLogger.info('DocumentProgress [$taskId]: ${(progress * 100).toStringAsFixed(0)}% at stage: $step');
    final callback = _callbacks[taskId];
    if (callback != null) {
      callback(progress, step);
    }
    final controller = _controllers[taskId];
    if (controller != null && !controller.isClosed) {
      controller.add({'progress': progress, 'step': step});
    }
  }

  /// Returns progress stream for a specific task.
  Stream<Map<String, dynamic>>? getProgressStream(String taskId) => _controllers[taskId]?.stream;

  /// Unregisters and closes resources for a finished task.
  void remove(String taskId) {
    _callbacks.remove(taskId);
    final controller = _controllers.remove(taskId);
    controller?.close();
  }

  /// Clears all listeners.
  void clear() {
    _callbacks.clear();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
/// Standard pipeline step string constants.
abstract final class DocumentProgressSteps {
  static const String preparing = 'Preparing';
  static const String reading = 'Reading';
  static const String validating = 'Validating';
  static const String processing = 'Processing';
  static const String writing = 'Writing';
  static const String cleaning = 'Cleaning';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String failed = 'Failed';
}
